#!/usr/bin/env python3
"""Regression tests for the cross-platform web launcher contract."""

import os
import shutil
import subprocess
import tempfile
import textwrap
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).parent


class StartWebLauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.project = Path(self.temp_dir.name) / "project"
        self.bin_dir = Path(self.temp_dir.name) / "bin"
        self.project.mkdir()
        self.bin_dir.mkdir()
        for name in ("start-web.sh", "start.sh", "config-default.ini", "docker-compose.web.yml"):
            shutil.copy2(ROOT / name, self.project / name)
        self.calls = Path(self.temp_dir.name) / "docker-calls.log"
        self.browser_calls = Path(self.temp_dir.name) / "browser-calls.log"
        self._write_command("curl", "printf '{\"services\": []}'\n")
        self._write_command("lsof", "exit 1\n")
        self._write_command("open", "printf '%s\\n' \"$*\" >> \"$BROWSER_CALLS\"\n")
        self._write_command("xdg-open", "printf '%s\\n' \"$*\" >> \"$BROWSER_CALLS\"\n")

    def tearDown(self):
        self.temp_dir.cleanup()

    def _write_command(self, name: str, body: str) -> None:
        path = self.bin_dir / name
        path.write_text("#!/bin/sh\n" + body, encoding="utf-8")
        path.chmod(0o755)

    def _docker_v2(self) -> None:
        self._write_command(
            "docker",
            textwrap.dedent(
                """
                printf '%s\n' "$*" >> "$DOCKER_CALLS"
                [ "$1" = "info" ] && exit 0
                [ "$1" = "compose" ] && [ "$2" = "version" ] && exit 0
                exit 0
                """
            ),
        )

    def _run(
        self,
        *args: str,
        path: str | None = None,
        extra_env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["DOCKER_CALLS"] = str(self.calls)
        env["BROWSER_CALLS"] = str(self.browser_calls)
        env["PATH"] = path or f"{self.bin_dir}:{env['PATH']}"
        env.update(extra_env or {})
        return subprocess.run(
            ["bash", str(self.project / "start-web.sh"), *args],
            cwd=Path(self.temp_dir.name),
            env=env,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )

    def test_compose_v2_starts_from_any_directory_and_creates_missing_data(self):
        self._docker_v2()
        result = self._run("--docker", "--no-open")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("compose -f", self.calls.read_text(encoding="utf-8"))
        self.assertIn("up -d --build", self.calls.read_text(encoding="utf-8"))
        self.assertEqual((self.project / "db.json").read_text(encoding="utf-8"), "{}\n")
        self.assertTrue((self.project / "files").is_dir())

    def test_legacy_compose_fallback(self):
        self._write_command(
            "docker",
            "[ \"$1\" = info ] && exit 0\n[ \"$1\" = compose ] && exit 1\nexit 0\n",
        )
        self._write_command(
            "docker-compose",
            "printf '%s\n' \"$*\" >> \"$DOCKER_CALLS\"\nexit 0\n",
        )
        result = self._run("--docker", "--no-open")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("up -d --build", self.calls.read_text(encoding="utf-8"))

    def test_invalid_data_path_is_never_deleted(self):
        self._docker_v2()
        (self.project / "db.json").mkdir()
        result = self._run("--docker", "--no-open")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-005", result.stderr)
        self.assertTrue((self.project / "db.json").is_dir())

    def test_existing_data_is_preserved(self):
        self._docker_v2()
        original = '{"token": "keep-me"}\n'
        (self.project / "db.json").write_text(original, encoding="utf-8")
        (self.project / "config.ini").write_text("[pdfgrabber]\n", encoding="utf-8")
        result = self._run("--docker", "--no-open")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.project / "db.json").read_text(encoding="utf-8"), original)

    def test_browser_opens_after_successful_health_check(self):
        self._docker_v2()
        result = self._run("--docker")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for _ in range(20):
            if self.browser_calls.exists():
                break
            time.sleep(0.05)
        self.assertIn("http://localhost:6066", self.browser_calls.read_text(encoding="utf-8"))

    def test_missing_docker_has_actionable_error(self):
        path = f"{self.bin_dir}:/usr/bin:/bin"
        result = self._run("--docker", "--no-open", path=path)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-001", result.stderr)

    def test_stopped_docker_times_out_with_actionable_error(self):
        self._write_command("docker", "exit 1\n")
        result = self._run(
            "--docker",
            "--no-open",
            extra_env={"PDFGRABBER_DOCKER_TIMEOUT": "0"},
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-002", result.stderr)

    def test_missing_compose_has_actionable_error(self):
        self._write_command(
            "docker",
            "[ \"$1\" = info ] && exit 0\n[ \"$1\" = compose ] && exit 1\nexit 0\n",
        )
        result = self._run("--docker", "--no-open")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-003", result.stderr)

    def test_port_conflict_is_reported_before_start(self):
        self._docker_v2()
        self._write_command("curl", "exit 1\n")
        self._write_command("lsof", "exit 0\n")
        result = self._run("--docker", "--no-open")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-004", result.stderr)

    def test_compose_failure_shows_startup_error(self):
        self._write_command(
            "docker",
            textwrap.dedent(
                """
                [ "$1" = "info" ] && exit 0
                [ "$1" = "compose" ] && [ "$2" = "version" ] && exit 0
                echo "$*" | grep -q 'up -d --build' && exit 42
                exit 0
                """
            ),
        )
        result = self._run("--docker", "--no-open")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-006", result.stderr)

    def test_health_timeout_shows_diagnostics(self):
        self._docker_v2()
        self._write_command("curl", "exit 1\n")
        result = self._run(
            "--docker",
            "--no-open",
            extra_env={"PDFGRABBER_HEALTH_TIMEOUT": "0"},
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-007", result.stderr)

    def test_local_mode_without_python_is_actionable(self):
        dirname = shutil.which("dirname")
        self.assertIsNotNone(dirname)
        os.symlink(dirname, self.bin_dir / "dirname")
        path = f"{self.bin_dir}:/bin"
        result = self._run("--local", "--no-open", path=path)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PG-START-101", result.stderr)

    def test_help_and_unknown_option(self):
        help_result = self._run("--help")
        self.assertEqual(help_result.returncode, 0)
        self.assertIn("--docker", help_result.stdout)
        bad_result = self._run("--unknown")
        self.assertNotEqual(bad_result.returncode, 0)
        self.assertIn("PG-START-000", bad_result.stderr)

    def test_windows_compose_progress_does_not_abort_launcher(self):
        powershell = shutil.which("pwsh") or shutil.which("powershell")
        if not powershell:
            self.skipTest("PowerShell is not installed")
        command = textwrap.dedent(
            """
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $env:LAUNCHER_SCRIPT, [ref]$tokens, [ref]$errors
            )
            $function = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Invoke-Compose"
            }, $true)
            Invoke-Expression $function.Extent.Text
            $ErrorActionPreference = "Stop"
            $script:UseComposeV2 = $true
            function docker {
                Write-Error "pdfgrabber-advanced-main-backend Built"
                $global:LASTEXITCODE = 0
            }
            Invoke-Compose @("up", "-d", "--build") 2>&1 | Out-Null
            if ($script:ComposeExitCode -ne 0) { exit 2 }
            function docker {
                Write-Error "real Docker failure"
                $global:LASTEXITCODE = 42
            }
            Invoke-Compose @("up", "-d", "--build") 2>&1 | Out-Null
            if ($script:ComposeExitCode -ne 42) { exit 3 }
            Write-Output "continued"
            """
        )
        env = os.environ.copy()
        env["LAUNCHER_SCRIPT"] = str(ROOT / "start-web.ps1")
        result = subprocess.run(
            [powershell, "-NoLogo", "-NoProfile", "-Command", command],
            env=env,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("continued", result.stdout)


if __name__ == "__main__":
    unittest.main()

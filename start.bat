@echo off
call "%~dp0start-web.bat" --local %*
exit /b %ERRORLEVEL%

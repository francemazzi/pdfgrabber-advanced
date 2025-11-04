#!/usr/bin/env python3
"""
Quick test script to verify PDFGrabber installation
Run this after creating the virtual environment to check if everything is working
"""

import sys
from pathlib import Path

def test_python_version():
    """Check Python version"""
    print("🔍 Verifica versione Python...")
    version = sys.version_info
    if version.major >= 3 and version.minor >= 10:
        print(f"   ✅ Python {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print(f"   ❌ Python {version.major}.{version.minor}.{version.micro} (richiesto 3.10+)")
        return False

def test_import(module_name, package_name=None):
    """Test if a module can be imported"""
    try:
        __import__(module_name)
        print(f"   ✅ {package_name or module_name}")
        return True
    except ImportError:
        print(f"   ❌ {package_name or module_name} (non installato)")
        return False

def test_dependencies():
    """Check if all required dependencies are installed"""
    print("\n📦 Verifica dipendenze...")
    
    deps = [
        ("fastapi", "FastAPI"),
        ("uvicorn", "Uvicorn"),
        ("websockets", "WebSockets"),
        ("pymupdf", "PyMuPDF"),
        ("rich", "Rich"),
        ("requests", "Requests"),
        ("Crypto", "PyCryptodome"),
        ("umsgpack", "u-msgpack-python"),
        ("tinydb", "TinyDB"),
        ("playwright", "Playwright"),
        ("lxml", "lxml"),
    ]
    
    results = []
    for module, name in deps:
        results.append(test_import(module, name))
    
    return all(results)

def test_project_structure():
    """Check if project files exist"""
    print("\n📁 Verifica struttura progetto...")
    
    required_files = [
        "backend/main.py",
        "backend/requirements.txt",
        "frontend/index.html",
        "main.py",
        "utils.py",
        "config.py",
    ]
    
    results = []
    for file_path in required_files:
        path = Path(file_path)
        if path.exists():
            print(f"   ✅ {file_path}")
            results.append(True)
        else:
            print(f"   ❌ {file_path} (mancante)")
            results.append(False)
    
    return all(results)

def main():
    """Run all tests"""
    print("=" * 50)
    print("  PDFGrabber - Test Installazione")
    print("=" * 50)
    
    results = []
    
    # Test Python version
    results.append(test_python_version())
    
    # Test dependencies
    results.append(test_dependencies())
    
    # Test project structure
    results.append(test_project_structure())
    
    # Summary
    print("\n" + "=" * 50)
    if all(results):
        print("✅ SUCCESSO! Tutto è installato correttamente!")
        print("\nPuoi avviare PDFGrabber con:")
        print("  ./start.sh      (macOS/Linux)")
        print("  start.bat       (Windows)")
    else:
        print("❌ ERRORI RILEVATI!")
        print("\nControlla i messaggi sopra e:")
        print("1. Assicurati che l'ambiente virtuale sia attivo")
        print("2. Reinstalla le dipendenze:")
        print("   pip install -r backend/requirements.txt")
        print("\nPer aiuto: docs/NO-DOCKER-TROUBLESHOOTING.md")
        sys.exit(1)
    print("=" * 50)

if __name__ == "__main__":
    main()



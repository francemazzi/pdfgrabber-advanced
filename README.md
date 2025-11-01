# What is this?

This is an unofficial fork from [PDFGrabber](https://github.com/FelixFrog/pdfgrabber), a vendor-agnostic script is used to download pdfs from different services.

❌ Important: the original project has been discontinued. For this reason, no more updates will be relased. Last update from source: 11 dec 2024

# Disclaimer

This script is provided "as is", without any type of warranty. I am not responsible of any harm that this may cause.
Even though this script exists, you are responsibile of the PDFs generated. Check if the backup of books is legal in your country.
Redistribution of PDFs is highly discouraged and not supported by the Author.

# 🌐 Web Interface (Easiest - Recommended!)

**NEW!** Beautiful web interface - no command line needed!

**🚀 Quick Start:**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Run:

   ```bash
   # Windows
   start-web.bat

   # macOS/Linux
   ./start-web.sh
   ```

3. Open your browser at **http://localhost:6066**
4. Click, login, and download! 🎉

📖 **Full Guide:** [WEB-UI-GUIDE.md](docs/WEB-UI-GUIDE.md)

**Features:**

- ✨ Modern, intuitive interface
- 📊 Real-time download progress
- 📁 Built-in file manager
- 📈 Statistics dashboard
- 🔍 Search functionality
- 📱 Mobile-friendly

---

# 🐳 CLI with Docker

For command-line users who prefer the terminal.

**Quick Start:**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Open terminal in the pdfgrabber directory
3. Run:
   ```bash
   docker-compose build
   docker-compose run --rm pdfgrabber
   ```

**Helper Scripts:**

- **Windows**: `start-pdfgrabber.bat`
- **Linux/macOS**: `./start-pdfgrabber.sh`
- **Make**: `make start`

📖 **Documentation:**

- [DOCKER-QUICKSTART.md](docs/DOCKER-QUICKSTART.md) (English)
- [DOCKER-GUIDA-RAPIDA.md](docs/DOCKER-GUIDA-RAPIDA.md) (Italiano)
- [DOCKER-GUIDE.md](docs/DOCKER-GUIDE.md) - Full guide

# Installation (Traditional Method)

1. download the latest version of [Python](https://www.python.org/downloads/)
   - on windows, when installing though the set up wizard, make sure to select the checkbox to add python to `PATH`
   - on linux and macos, use your package manager of choice (`brew install python3` or `apt install python3`, etc...)
2. downlaod the pdfgrabber repo
   - using git: `git clone https://github.com/RealRoti/pdfgrabber-advanced`
   - manually: download the zip (green button labeled "code") and extract it
3. open your local clone of pdfgrabber
4. open the terminal in that directory and run:
   1. `pip install -r requirements.txt` (takes care of installing every needed libraries)
   2. run the script
      - `python3 main.py` (linux and macos)
      - `py main.py` (windows)
5. once inside the pdfgrabber CLI:
   - press `r`: register a new account
   - choose what to do (it's listed):
     - to download a book: press `d` and follow the instructions.
     - the output file will be `files/<service>/<book name>.pdf`

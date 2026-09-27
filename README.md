# 🔐 PDFGrabber Advanced - Security Research Tool

> **⚠️ WARNING:** This is a security research and educational tool. Read the full legal disclaimer below before proceeding.

[![Research Purpose](https://img.shields.io/badge/Purpose-Security%20Research-yellow)](https://github.com/RealRoti/pdfgrabber-advanced)
[![Educational Use](https://img.shields.io/badge/Use-Educational%20Only-red)](https://github.com/RealRoti/pdfgrabber-advanced)
[![Not for Piracy](https://img.shields.io/badge/Piracy-Not%20Supported-critical)](https://github.com/RealRoti/pdfgrabber-advanced)
[![Non-Commercial](https://img.shields.io/badge/License-Non--Commercial-blue)](LICENSE)

---

# What is this?

This is an unofficial fork from [PDFGrabber](https://github.com/FelixFrog/pdfgrabber), a vendor-agnostic script is used to download pdfs from different services.

❌ Important: the original project has been discontinued. For this reason, no more updates will be relased. Last update from source: 11 dec 2024

---

# ⚠️ IMPORTANT LEGAL DISCLAIMER / DISCLAIMER LEGALE IMPORTANTE

## 🔬 EDUCATIONAL AND SECURITY RESEARCH PURPOSES ONLY

This software is provided **strictly for educational and security research purposes** to:

- Demonstrate security vulnerabilities in digital content protection systems
- Conduct academic research on DRM implementations
- Help content providers identify and improve their security measures
- Promote awareness about digital rights and content protection weaknesses

## 🚫 THIS SOFTWARE MUST NOT BE USED FOR:

- Unauthorized access to copyrighted materials
- Circumventing digital rights management (DRM) for illegal purposes
- Redistributing protected content without permission
- Any commercial use or profit
- Violating terms of service of any platform

## ⚖️ LEGAL NOTICE:

- Users are **solely responsible** for ensuring their use complies with local laws
- The circumvention of DRM may be **illegal in your jurisdiction** (DMCA in USA, EU Copyright Directive, etc.)
- This tool is intended to demonstrate the need for improved security measures by content providers
- The authors assume **NO responsibility** for misuse of this software
- By using this software, you acknowledge that you understand the legal implications in your country

## 📚 RESPONSIBLE USE:

- Only use with content you **legally own** or have explicit permission to access
- Check your local laws regarding DRM circumvention for research purposes
- Contact content providers directly if you discover security vulnerabilities
- Do not share, redistribute, or publish any protected content obtained using this tool

## 🇮🇹 AVVISO PER UTENTI ITALIANI:

La circumvenzione di protezioni tecnologiche può violare il Codice dei Diritti d'Autore italiano (Legge 633/1941 e successive modifiche). Questo software è fornito esclusivamente per scopi di ricerca e studio personale su contenuti di cui si possiede già legittima licenza d'uso.

## 📄 LICENSE:

This software is licensed under a **Non-Commercial License**. See the [LICENSE](LICENSE) file for details. Commercial use is strictly prohibited.

---

# Original Disclaimer

This script is provided "as is", without any type of warranty. I am not responsible of any harm that this may cause.
Even though this script exists, you are responsibile of the PDFs generated. Check if the backup of books is legal in your country.
Redistribution of PDFs is highly discouraged and not supported by the Author.

# 🌐 Web Interface (Easiest - Recommended!)

One launcher handles Docker and the local Python installation. Docker is the
recommended default: press Enter when the launcher asks which mode to use.

**🚀 Quick Start:**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Clone or download this repository:

   ```bash
   git clone https://github.com/RealRoti/pdfgrabber-advanced
   cd pdfgrabber-advanced
   ```

   Or download the ZIP from the green "Code" button and extract it

3. Run the start script:

   ```bash
   # Windows
   start-web.bat

   # macOS/Linux (works also after downloading the ZIP)
   bash start-web.sh
   ```

4. Press Enter to use Docker. The launcher starts Docker Desktop when possible,
   waits until PDFGrabber is healthy, and opens **http://localhost:6066**.
5. Click, login, and download! 🎉

For unattended startup, use `bash start-web.sh --docker` or
`start-web.bat --docker`. Add `--no-open` to avoid opening the browser.

📖 **Full Guide:** [WEB-UI-GUIDE.md](docs/WEB-UI-GUIDE.md)

**Features:**

- ✨ Modern, intuitive interface
- 📊 Real-time download progress
- 📁 Built-in file manager
- 📈 Statistics dashboard
- 🔍 Search functionality
- 📱 Mobile-friendly
- 🔑 **NEW: bSmart Dynamic** - Auto-extracts encryption keys (more reliable!)

### 🆕 bSmart Dynamic - What's New?

PDFGrabber now includes **two versions** of the bSmart service:

- **bSmart** - Standard version (fast, but may stop working if bSmart updates encryption)
- **bSmart Dynamic (Auto-Key)** ⭐ - Automatically extracts encryption keys from the website
  - ✅ More reliable and future-proof
  - ✅ Continues working even when bSmart updates their security
  - ✅ Only ~2 seconds slower on first use (then uses cache)

**Which one to use?** We recommend **bSmart Dynamic** for better long-term reliability!

📖 **Learn more:** [bSmart Dynamic Guide](docs/BSMART-DYNAMIC-INFO.md)

### 🔄 Update Scripts

Keep your PDFGrabber installation up to date with these convenient scripts:

**Windows:**
```cmd
update.bat
```

**Linux/macOS:**
```bash
./update.sh
```

These scripts will:
1. ✅ Pull latest code from Git
2. ✅ Rebuild and restart with new code
3. ✅ Verify the Web UI
4. ✅ Open the browser at localhost:6066

Perfect for getting new features and bug fixes!

---

# 🐳 CLI with Docker

For command-line users who prefer the terminal.

**Quick Start:**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Open terminal in the pdfgrabber directory
3. Run:
   ```bash
   docker compose build
   docker compose run --rm pdfgrabber
   ```

**Helper Scripts:**

- **Windows**: `start-pdfgrabber.bat`
- **Linux/macOS**: `./start-pdfgrabber.sh`
- **Make**: `make start`

📖 **Documentation:**

- [DOCKER-QUICKSTART.md](docs/DOCKER-QUICKSTART.md) (English)
- [DOCKER-GUIDA-RAPIDA.md](docs/DOCKER-GUIDA-RAPIDA.md) (Italiano)
- [DOCKER-GUIDE.md](docs/DOCKER-GUIDE.md) - Full guide

# 💻 Installation Without Docker

**For users who don't have Docker installed**, you can run PDFGrabber locally using Python virtual environments (no dependency conflicts!).

## Web Interface (Recommended)

**Quick Start:**

1. **Download Python 3.10 or higher** from [python.org](https://www.python.org/downloads/)

   - **Windows**: Check "Add Python to PATH" during installation
   - **macOS**: `brew install python3`
   - **Linux**: `sudo apt install python3 python3-venv`

2. **Download PDFGrabber:**

   ```bash
   git clone https://github.com/RealRoti/pdfgrabber-advanced
   cd pdfgrabber-advanced
   ```

   Or download the ZIP from the green "Code" button and extract it

3. **Run the same launcher and choose option 2:**

   ```bash
   # Windows
   start-web.bat --local

   # macOS/Linux
   bash start-web.sh --local
   ```

The script will:

- ✅ Create an isolated virtual environment
- ✅ Install all dependencies automatically
- ✅ Start the web server on **http://localhost:6066**
- ✅ Open your browser automatically

**That's it!** No Docker, no conflicts, no hassle! 🎉

---

## CLI (Command Line)

For terminal enthusiasts who prefer the classic interface:

1. **Create virtual environment:**

   ```bash
   python3 -m venv venv

   # Activate it:
   source venv/bin/activate  # macOS/Linux
   venv\Scripts\activate     # Windows
   ```

2. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

3. **Run PDFGrabber CLI:**

   ```bash
   python3 main.py  # macOS/Linux
   python main.py   # Windows
   ```

4. **Using the CLI:**
   - Press `r`: Register a new profile
   - Press `d`: Download a book
   - Downloaded files: `files/<service>/<book name>.pdf`

**Why Virtual Environment?**

- ✅ No dependency conflicts with other Python projects
- ✅ Isolated environment with only required packages
- ✅ Easy to remove (just delete the `venv` folder)
- ✅ No admin/sudo rights needed

**Troubleshooting:** Having issues? Check the [Troubleshooting Guide](docs/NO-DOCKER-TROUBLESHOOTING.md) 🔧

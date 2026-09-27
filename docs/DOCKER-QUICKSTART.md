# 🐳 Docker Quick Start for PDFGrabber

## 🎯 Why Use Docker?

✅ **No Python installation needed** - everything included  
✅ **Zero configuration issues** - works first time  
✅ **Same on Windows, Mac & Linux** - no differences  
✅ **Isolated from your system** - no conflicts  
✅ **Playwright pre-configured** - browsers included  

---

## 📥 Installing Docker Desktop

### 1️⃣ Download Docker Desktop

Go to: **https://www.docker.com/products/docker-desktop/**

- **Windows**: Download for Windows
- **macOS Intel**: Download for Mac with Intel chip  
- **macOS Apple Silicon (M1/M2/M3)**: Download for Mac with Apple chip
- **Linux**: Follow instructions on the website

### 2️⃣ Install Docker Desktop

- **Windows/Mac**: Run the downloaded file and follow the wizard
- **Linux**: Use terminal (see DOCKER-GUIDE.md for details)

### 3️⃣ Start Docker Desktop

- Open Docker Desktop from Start menu (Windows) or Launchpad (Mac)
- **Wait for the icon to turn green** (means it's ready)

---

## 🚀 How to Use PDFGrabber

### First Time

1. **Open terminal** in the `pdfgrabber-advanced` folder
   - Windows: Shift + right-click → "Open PowerShell window here"
   - Mac: Drag folder onto Terminal icon
   - Linux: Right-click → "Open in terminal"

2. **Build the Docker image** (takes 5-10 minutes)
   ```bash
   docker compose build
   ```

3. **Start PDFGrabber**
   ```bash
   docker compose run --rm pdfgrabber
   ```

### Subsequent Uses

Every time you want to use PDFGrabber, just one command:

```bash
docker compose run --rm pdfgrabber
```

---

## 📁 Where Are My Files?

Downloaded PDFs are in the `files/` folder on YOUR computer (not inside Docker):

```
pdfgrabber-advanced/
├── files/
│   ├── bsm/       ← Your bSmart PDFs
│   ├── mcm/       ← Your MEE2 PDFs
│   └── ...
├── config.ini     ← Your settings
└── db.json       ← Your users and tokens
```

**You can access them normally** with File Explorer or Finder!

---

## ⚡ Essential Commands

```bash
# Build/rebuild image (first time or after updates)
docker compose build

# Start PDFGrabber
docker compose run --rm pdfgrabber

# Stop everything
docker compose down

# Rebuild from scratch (if something goes wrong)
docker compose build --no-cache
```

---

## 🔧 Common Issues

### "Docker is not running"
➡️ Open Docker Desktop and wait for it to turn green

### "Cannot connect to the Docker daemon"
➡️ Restart Docker Desktop

### Build too slow
➡️ It's normal first time (downloads ~800MB), then it's fast

### Generic errors
➡️ Try rebuilding from scratch:
```bash
docker compose down
docker compose build --no-cache
```

---

## ❓ Frequently Asked Questions

**Q: Do I need to keep Docker Desktop always open?**  
A: Only when using PDFGrabber. You can close it afterwards.

**Q: Are my data safe?**  
A: Yes! Everything is saved on your computer, not inside Docker.

**Q: How much space does it take?**  
A: About 1.3 GB (Docker + PDFGrabber image).

**Q: Can I use PDFGrabber without Docker?**  
A: Yes, follow traditional instructions in README.md.

**Q: Does it work offline?**  
A: Yes, after first build. But you need internet to download books!

---

## 📚 Full Documentation

For a detailed guide with all explanations, see: **[DOCKER-GUIDE.md](DOCKER-GUIDE.md)**

For Italian version: **[DOCKER-GUIDA-RAPIDA.md](DOCKER-GUIDA-RAPIDA.md)**

---

## 🎉 Ultra-Quick Summary

```bash
# 1. Install Docker Desktop (once)
#    https://www.docker.com/products/docker-desktop/

# 2. Build (first time)
docker compose build

# 3. Use PDFGrabber (always)
docker compose run --rm pdfgrabber

# 4. Find PDFs
#    In folder: files/
```

**That's it! Happy downloading! 📚✨**


# 🐳 Docker Guide for PDFGrabber - For Beginners

This guide will help you use PDFGrabber with Docker, even if you've never used Docker before!

## 📋 What is Docker?

Docker is like a "magic box" that contains everything needed to run an application:
- The right operating system
- Python in the correct version
- All necessary libraries
- Browsers to download PDFs

**Main advantage:** You don't need to install anything on your computer except Docker itself!

---

## 🎯 Installing Docker Desktop

### Windows

1. Go to [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Click on "Download for Windows"
3. Run the downloaded `Docker Desktop Installer.exe` file
4. Follow the installation wizard (leave all default options)
5. Restart your computer when prompted
6. After reboot, open Docker Desktop from the Start menu
7. Accept the terms of service
8. **Wait** for Docker Desktop to fully start (green icon in bottom left)

**Windows Requirements:**
- Windows 10/11 (64-bit)
- WSL 2 (Windows Subsystem for Linux) - installs automatically

### macOS

1. Go to [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. Choose the right version:
   - **Apple Silicon (M1/M2/M3)**: Download for Mac with Apple chip
   - **Intel**: Download for Mac with Intel chip
3. Open the downloaded `.dmg` file
4. Drag Docker to Applications
5. Open Docker from Launchpad
6. Accept the terms of service
7. **Wait** for Docker Desktop to fully start (green icon at top)

**macOS Requirements:**
- macOS 11 or higher

### Linux

1. Open the terminal
2. Install Docker:
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (to avoid using sudo)
sudo usermod -aG docker $USER
```
3. Restart your computer or logout/login
4. Install Docker Compose:
```bash
sudo apt-get install docker-compose-plugin
```

---

## 🚀 How to Use PDFGrabber with Docker

### Method 1: Using Docker Desktop (GUI) - RECOMMENDED FOR BEGINNERS

#### First Time - Container Creation

1. **Open Docker Desktop**
   - Make sure it's running (green icon)

2. **Open Terminal in PDFGrabber folder**
   - **Windows**: Open File Explorer → go to pdfgrabber-advanced folder → click on address bar → type `cmd` and press Enter
   - **macOS**: Drag the pdfgrabber-advanced folder onto the Terminal icon
   - **Linux**: Right-click in folder → "Open in Terminal"

3. **Build the Docker image** (first time only)
   ```bash
   docker-compose build
   ```
   ⏱️ This takes 5-10 minutes the first time (downloads everything needed)

4. **Start PDFGrabber**
   ```bash
   docker-compose run --rm pdfgrabber
   ```
   
   ✅ The PDFGrabber interface will open as usual!

#### Subsequent Uses

Every time you want to use PDFGrabber:

1. Open terminal in the pdfgrabber-advanced folder
2. Run:
   ```bash
   docker-compose run --rm pdfgrabber
   ```

### Method 2: Using Terminal Only (Advanced Users)

```bash
# First time: build the image
docker-compose build

# Every time: start PDFGrabber
docker-compose run --rm pdfgrabber
```

---

## 📁 Where to Find Downloaded Files

Downloaded PDFs are in the `files/` folder inside the pdfgrabber-advanced directory, exactly like the non-Docker version!

```
pdfgrabber-advanced/
├── files/
│   ├── bsm/          ← bSmart PDFs
│   ├── mcm/          ← MEE2 PDFs
│   └── ...           ← Other services
├── config.ini        ← Your configuration
└── db.json          ← Your database (users, tokens)
```

**Important:** These files are on YOUR computer, not inside Docker! You can access them normally with File Explorer (Windows), Finder (macOS), or file manager (Linux).

---

## 🎮 Useful Docker Desktop Commands

### View Active Containers

1. Open Docker Desktop
2. Click on "Containers" in the sidebar
3. You'll see all containers (running and stopped)

### Stop PDFGrabber

If PDFGrabber is running, you can stop it:
- **In the CLI interface**: press `q` to quit
- **In terminal**: press `Ctrl+C` (Windows/Linux) or `Cmd+C` (macOS)

### Remove Everything and Start Over

If something goes wrong and you want to start from scratch:

```bash
# Remove the container
docker-compose down

# Also remove the image
docker rmi pdfgrabber-advanced:latest

# Rebuild
docker-compose build
```

**Note:** Your PDFs, configurations, and database will NOT be deleted!

---

## 🔧 Troubleshooting

### "Docker is not running"
- Open Docker Desktop and wait for it to fully start
- The icon at the bottom (Windows) or top (macOS) must be green

### "permission denied" (Linux)
```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Then logout and login
```

### "port is already allocated"
- This shouldn't happen with PDFGrabber, but if it does:
  ```bash
  docker-compose down
  ```

### "Cannot connect to the Docker daemon"
- Make sure Docker Desktop is open and running
- Restart Docker Desktop

### Very slow build
- It's normal the first time (downloads ~500MB)
- May take 10-15 minutes on slow connections
- Subsequent times will be instant

### "playwright install" error
- Rebuild the image:
  ```bash
  docker-compose build --no-cache
  ```

---

## 💡 Frequently Asked Questions

### Do I need to keep Docker Desktop always open?
**Yes**, only when using PDFGrabber. You can close it when not in use.

### Are my data safe?
**Yes**, all your files (PDFs, configurations, database) are saved on your computer, not inside Docker.

### Can I use PDFGrabber without Docker?
**Yes**, you can follow the normal instructions in the main README.md.

### Does Docker take up a lot of space?
- Docker Desktop: ~500 MB
- PDFGrabber Image: ~800 MB
- Total: ~1.3 GB

### Can I delete Docker afterwards?
**Yes**, if you no longer need it:
1. Uninstall Docker Desktop like any normal program
2. Your PDFs and configurations will remain intact

### Does Docker work offline?
**Yes**, after the first image build, you can use PDFGrabber even without internet (but obviously you won't be able to download books!).

---

## 🎓 Command Explanation

### `docker-compose build`
Builds the PDFGrabber "image" (like creating a mold). Done only the first time.

### `docker-compose run --rm pdfgrabber`
- `run`: Start PDFGrabber
- `--rm`: Automatically remove the container when you exit (keeps things clean)
- `pdfgrabber`: Name of the service to start

### `docker-compose down`
Stops and removes all containers of the project.

---

## 📊 Comparison: With Docker vs Without Docker

| Feature | Without Docker | With Docker |
|---------|----------------|-------------|
| **Installation** | 5+ steps, 20+ minutes | 2 commands, 10 minutes |
| **Python version issues** | Possible | Impossible |
| **Playwright issues** | Frequent | Never |
| **Works same everywhere** | No | Yes |
| **Easy to update** | Complicated | `docker-compose build` |
| **Disk space** | ~200 MB | ~1.3 GB |
| **Isolation** | No | Complete |

---

## 🆘 Need Help?

1. **Check this guide** - covers 99% of problems
2. **Verify Docker Desktop** - must be green/active
3. **Restart Docker Desktop** - solves many issues
4. **Rebuild everything** - `docker-compose down && docker-compose build --no-cache`

---

## ✅ Quick Summary

For those in a hurry:

```bash
# 1. Install Docker Desktop (once)
# Download from: https://www.docker.com/products/docker-desktop/

# 2. Open terminal in pdfgrabber-advanced folder

# 3. First time
docker-compose build

# 4. Every time you want to use PDFGrabber
docker-compose run --rm pdfgrabber

# 5. PDFs are in: files/
```

**That's it! Happy downloading! 📚**


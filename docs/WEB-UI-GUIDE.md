# 🌐 PDFGrabber Web UI Guide

## Overview

PDFGrabber Web UI is a modern, intuitive web interface for downloading your digital books. No more command line - just click and download!

## 🚀 Quick Start

### Option 1: Using Helper Scripts (Easiest)

**Windows:**

```bash
# Double-click
start-web.bat

# Or from command line
.\start-web.bat
```

**macOS/Linux:**

```bash
./start-web.sh
```

### Option 2: Using Docker Compose

```bash
# Build images (first time only)
docker-compose -f docker-compose.web.yml build

# Start the web UI
docker-compose -f docker-compose.web.yml up -d

# Open browser at http://localhost:6066
```

### Option 3: Using Make

```bash
make web-start
```

---

## 🌐 Accessing the Web UI

Once started, open your browser and go to:

**👉 http://localhost:6066**

---

## 📖 How to Use

### 1️⃣ **Select a Service**

<img src="https://via.placeholder.com/800x400/667eea/ffffff?text=Service+Selection+Screen" alt="Service Selection">

- Click on any service card (bSmart, Scuolabook, etc.)
- You'll be prompted to log in

### 2️⃣ **Login**

<img src="https://via.placeholder.com/400x300/764ba2/ffffff?text=Login+Modal" alt="Login">

- Enter your username and password
- Click "Login"
- Your token is securely stored in the database

### 3️⃣ **Browse Your Library**

<img src="https://via.placeholder.com/800x500/667eea/ffffff?text=Library+View" alt="Library">

Features:

- 🔍 Search for books by title or ID
- ☑️ Select multiple books
- 📥 Download single or multiple books
- 📊 See book details

### 4️⃣ **Download Books**

<img src="https://via.placeholder.com/600x400/764ba2/ffffff?text=Download+Progress" alt="Download">

- Select books using checkboxes
- Click "Download X Selected" button
- Watch real-time progress
- Books are saved to `files/` folder

### 5️⃣ **View Downloaded Files**

<img src="https://via.placeholder.com/800x400/667eea/ffffff?text=Files+View" alt="Files">

- Click "My Files" in the header
- See all your downloaded PDFs
- Click "Open" to view in browser
- Files are organized by service

### 6️⃣ **Check Statistics**

<img src="https://via.placeholder.com/800x400/764ba2/ffffff?text=Statistics" alt="Stats">

- Click "Statistics" in the header
- View total files, size, and services used
- Track your downloads

---

## 🎨 Features

### ✅ User-Friendly Interface

- Modern, clean design
- Intuitive navigation
- Responsive (works on mobile too!)

### ✅ Real-Time Progress

- WebSocket-based live updates
- See download percentage
- Progress bars for each book

### ✅ Batch Downloads

- Select multiple books
- Download all at once
- Queue management

### ✅ Search & Filter

- Search books by title
- Filter by service
- Quick access

### ✅ File Management

- View all downloaded files
- Organized by service
- Direct PDF preview

### ✅ Statistics Dashboard

- Track total downloads
- Monitor disk usage
- Service usage breakdown

---

## 🛠️ Architecture

```
┌─────────────────────────────────────┐
│   Browser (http://localhost:6066)   │
│                                     │
│   Frontend (Nginx + HTML/JS)       │
└─────────────────┬───────────────────┘
                  │
                  │ HTTP/WebSocket
                  │
┌─────────────────▼───────────────────┐
│   Backend API (FastAPI)             │
│                                     │
│   - REST API                        │
│   - WebSocket for downloads         │
│   - Service integration             │
└─────────────────┬───────────────────┘
                  │
                  │ Uses
                  │
┌─────────────────▼───────────────────┐
│   PDFGrabber Core                   │
│                                     │
│   - utils.py                        │
│   - services/                       │
│   - Playwright automation           │
└─────────────────────────────────────┘
```

---

## 🔧 Management Commands

### Start the Web UI

```bash
docker-compose -f docker-compose.web.yml up -d
```

### Stop the Web UI

```bash
docker-compose -f docker-compose.web.yml down
```

### View Logs

```bash
# All logs
docker-compose -f docker-compose.web.yml logs -f

# Backend only
docker-compose -f docker-compose.web.yml logs -f backend

# Frontend only
docker-compose -f docker-compose.web.yml logs -f frontend
```

### Rebuild Images

```bash
docker-compose -f docker-compose.web.yml build --no-cache
```

### Restart Services

```bash
docker-compose -f docker-compose.web.yml restart
```

### Check Status

```bash
docker-compose -f docker-compose.web.yml ps
```

---

## 📁 File Structure

```
pdfgrabber-advanced/
├── backend/
│   ├── Dockerfile
│   ├── main.py              # FastAPI application
│   ├── requirements.txt
│   └── api/
│       └── __init__.py
├── frontend/
│   ├── Dockerfile
│   ├── index.html           # Main UI
│   ├── nginx.conf           # Nginx configuration
│   └── static/
│       └── js/
│           └── app.js       # Frontend logic
├── docker-compose.web.yml   # Docker Compose config
├── start-web.sh             # Launch script (Linux/macOS)
└── start-web.bat            # Launch script (Windows)
```

---

## 🔌 API Endpoints

The backend exposes these endpoints:

### Services

- `GET /api/services` - List all available services
- `POST /api/services/{service}/login` - Login to service
- `POST /api/services/{service}/check-token` - Verify token
- `POST /api/services/{service}/library` - Get user's library

### Files

- `GET /api/files` - List downloaded files
- `GET /api/files/{service}/{filename}` - Download specific file

### Stats

- `GET /api/stats` - Get download statistics

### WebSocket

- `WS /ws/download/{client_id}` - Download books with real-time progress

API documentation available at: **http://localhost:6066/docs** (Swagger UI)

---

## 🌐 Port Configuration

The Web UI runs on **port 6066** by default.

To change the port, edit `docker-compose.web.yml`:

```yaml
services:
  frontend:
    ports:
      - "YOUR_PORT:80" # Change YOUR_PORT to your desired port
```

Then restart:

```bash
docker-compose -f docker-compose.web.yml down
docker-compose -f docker-compose.web.yml up -d
```

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Check what's using port 6066
lsof -i :6066  # macOS/Linux
netstat -ano | findstr :6066  # Windows

# Stop the conflicting service or change port in docker-compose.web.yml
```

### Backend Not Starting

```bash
# Check backend logs
docker-compose -f docker-compose.web.yml logs backend

# Common fix: rebuild
docker-compose -f docker-compose.web.yml build backend --no-cache
docker-compose -f docker-compose.web.yml up -d
```

### Frontend Shows Error

```bash
# Check if backend is healthy
docker-compose -f docker-compose.web.yml ps

# Restart frontend
docker-compose -f docker-compose.web.yml restart frontend
```

### Downloads Not Working

1. Check WebSocket connection in browser console (F12)
2. Verify token is valid
3. Check backend logs for errors
4. Ensure `files/` directory has write permissions

### Can't Access Web UI

```bash
# Verify services are running
docker-compose -f docker-compose.web.yml ps

# Check if port is exposed
docker ps | grep pdfgrabber

# Try accessing backend directly
curl http://localhost:8080/api/services
```

---

## 💡 Tips & Tricks

### 1. Keep Browser Tab Open

Keep the download page open while downloading to see real-time progress.

### 2. Batch Downloads

Select multiple books from the same service to download them all in one go.

### 3. Search Feature

Use the search box to quickly find books by title or ID.

### 4. Direct PDF Access

Downloaded PDFs are in `files/{service}/` - you can access them directly from your file manager.

### 5. Mobile Access

Access from your phone using your computer's IP:

```
http://YOUR_COMPUTER_IP:6066
```

---

## 🔒 Security Notes

- The Web UI runs **locally** on your machine
- No data is sent to external servers
- Credentials are stored in local `db.json`
- Use only on trusted networks

---

## 🆚 Web UI vs CLI

| Feature            | CLI    | Web UI     |
| ------------------ | ------ | ---------- |
| Ease of use        | ⭐⭐   | ⭐⭐⭐⭐⭐ |
| Visual feedback    | ⭐⭐   | ⭐⭐⭐⭐⭐ |
| Batch downloads    | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Real-time progress | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| File management    | ⭐⭐   | ⭐⭐⭐⭐⭐ |
| Search             | ❌     | ✅         |
| Statistics         | ❌     | ✅         |
| Mobile friendly    | ❌     | ✅         |

---

## 🔄 Updates

To update to the latest version:

```bash
# Pull latest code
git pull

# Rebuild images
docker-compose -f docker-compose.web.yml build

# Restart services
docker-compose -f docker-compose.web.yml down
docker-compose -f docker-compose.web.yml up -d
```

---

## 📝 Development

### Run Backend Locally (without Docker)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

### Run Frontend Locally

```bash
cd frontend
python -m http.server 3000
# Open http://localhost:3000
```

---

## ❓ FAQ

**Q: Can I use both CLI and Web UI?**  
A: Yes! They share the same database and files.

**Q: Is it safe to close the browser during download?**  
A: No, keep the browser open. The backend continues, but you won't see progress.

**Q: Can multiple users access the Web UI?**  
A: It's designed for single-user local use. Network access is possible but not recommended for security.

**Q: Does it work offline?**  
A: The UI works offline, but you need internet to download books from services.

**Q: How much disk space do I need?**  
A: Docker images: ~1.5GB. Plus space for your downloaded PDFs.

---

## 🎉 Enjoy!

You now have a beautiful, modern interface for PDFGrabber!

**Open http://localhost:6066 and start downloading! 📚✨**

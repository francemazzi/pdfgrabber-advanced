# Makefile for PDFGrabber Docker
# Simplifies common commands

.PHONY: help build start run rebuild clean update web-build web-start web-stop web-logs web-restart

# Default target
help:
	@echo "📚 PDFGrabber Docker Commands:"
	@echo ""
	@echo "🌐 Web Interface (Recommended):"
	@echo "  make web-start     - Start Web UI at http://localhost:6066"
	@echo "  make web-stop      - Stop Web UI"
	@echo "  make web-logs      - View Web UI logs"
	@echo "  make web-restart   - Restart Web UI"
	@echo "  make web-build     - Build Web UI images"
	@echo ""
	@echo "🖥️  CLI Interface:"
	@echo "  make build         - Build Docker image (first time)"
	@echo "  make start         - Start PDFGrabber CLI"
	@echo "  make run           - Alias for start"
	@echo "  make rebuild       - Rebuild image from scratch"
	@echo "  make clean         - Remove containers and images"
	@echo "  make update        - Update PDFGrabber (git pull + rebuild)"
	@echo ""
	@echo "💡 Most common: make web-start"

# Build Docker image
build:
	@echo "📦 Building Docker image..."
	docker-compose build
	@echo "✅ Image built!"

# Start PDFGrabber
start:
	@echo "🚀 Starting PDFGrabber..."
	docker-compose run --rm pdfgrabber
	@echo "✅ Done! PDFs are in files/"

# Alias for start
run: start

# Rebuild from scratch
rebuild:
	@echo "🔄 Full rebuild..."
	docker-compose down
	docker-compose build --no-cache
	@echo "✅ Rebuild completed!"

# Clean everything
clean:
	@echo "🧹 Cleaning containers and images..."
	docker-compose down --rmi all -v
	@echo "✅ Cleaning completed!"
	@echo "⚠️  Your PDFs, config and database are safe!"

# Update PDFGrabber
update:
	@echo "🔄 Updating PDFGrabber..."
	git pull
	docker-compose build
	@echo "✅ Update completed!"

# ============== WEB UI COMMANDS ==============

# Build Web UI images
web-build:
	@echo "📦 Building Web UI images..."
	docker-compose -f docker-compose.web.yml build
	@echo "✅ Web UI images built!"

# Start Web UI
web-start:
	@echo "🚀 Starting PDFGrabber Web UI..."
	docker-compose -f docker-compose.web.yml up -d
	@echo "✅ Web UI started!"
	@echo "🌐 Open http://localhost:6066 in your browser"

# Stop Web UI
web-stop:
	@echo "🛑 Stopping Web UI..."
	docker-compose -f docker-compose.web.yml down
	@echo "✅ Web UI stopped!"

# View Web UI logs
web-logs:
	@echo "📋 Viewing Web UI logs (Ctrl+C to exit)..."
	docker-compose -f docker-compose.web.yml logs -f

# Restart Web UI
web-restart:
	@echo "🔄 Restarting Web UI..."
	docker-compose -f docker-compose.web.yml restart
	@echo "✅ Web UI restarted!"

# Full Web rebuild
web-rebuild:
	@echo "🔄 Full Web UI rebuild..."
	docker-compose -f docker-compose.web.yml down
	docker-compose -f docker-compose.web.yml build --no-cache
	docker-compose -f docker-compose.web.yml up -d
	@echo "✅ Web UI rebuild completed!"
	@echo "🌐 Open http://localhost:6066"


# Makefile for PDFGrabber Docker
# Simplifies common commands

.PHONY: help build start run rebuild clean update web-build web-start web-stop web-logs web-restart

COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

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
	$(COMPOSE) build
	@echo "✅ Image built!"

# Start PDFGrabber
start:
	@echo "🚀 Starting PDFGrabber..."
	$(COMPOSE) run --rm pdfgrabber
	@echo "✅ Done! PDFs are in files/"

# Alias for start
run: start

# Rebuild from scratch
rebuild:
	@echo "🔄 Full rebuild..."
	$(COMPOSE) down
	$(COMPOSE) build --no-cache
	@echo "✅ Rebuild completed!"

# Clean everything
clean:
	@echo "🧹 Cleaning containers and images..."
	$(COMPOSE) down --rmi all -v
	@echo "✅ Cleaning completed!"
	@echo "⚠️  Your PDFs, config and database are safe!"

# Update PDFGrabber
update:
	@echo "🔄 Updating PDFGrabber..."
	git pull
	$(COMPOSE) build
	@echo "✅ Update completed!"

# ============== WEB UI COMMANDS ==============

# Build Web UI images
web-build:
	@echo "📦 Building Web UI images..."
	$(COMPOSE) -f docker-compose.web.yml build
	@echo "✅ Web UI images built!"

# Start Web UI
web-start:
	bash ./start-web.sh --docker

# Stop Web UI
web-stop:
	@echo "🛑 Stopping Web UI..."
	$(COMPOSE) -f docker-compose.web.yml down
	@echo "✅ Web UI stopped!"

# View Web UI logs
web-logs:
	@echo "📋 Viewing Web UI logs (Ctrl+C to exit)..."
	$(COMPOSE) -f docker-compose.web.yml logs -f

# Restart Web UI
web-restart:
	@echo "🔄 Restarting Web UI..."
	$(COMPOSE) -f docker-compose.web.yml restart
	@echo "✅ Web UI restarted!"

# Full Web rebuild
web-rebuild:
	@echo "🔄 Full Web UI rebuild..."
	$(COMPOSE) -f docker-compose.web.yml down
	$(COMPOSE) -f docker-compose.web.yml build --no-cache
	$(COMPOSE) -f docker-compose.web.yml up -d
	@echo "✅ Web UI rebuild completed!"
	@echo "🌐 Open http://localhost:6066"

# Makefile for PDFGrabber Docker
# Simplifies common commands

.PHONY: help build start run rebuild clean update

# Default target
help:
	@echo "📚 PDFGrabber Docker Commands:"
	@echo ""
	@echo "  make build     - Build Docker image (first time)"
	@echo "  make start     - Start PDFGrabber (use this!)"
	@echo "  make run       - Alias for start"
	@echo "  make rebuild   - Rebuild image from scratch"
	@echo "  make clean     - Remove containers and images"
	@echo "  make update    - Update PDFGrabber (git pull + rebuild)"
	@echo ""
	@echo "💡 Most common command: make start"

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


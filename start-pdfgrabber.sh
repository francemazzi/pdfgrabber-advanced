#!/bin/bash
# Helper script to start PDFGrabber with Docker
# For Linux and macOS

set -e

echo "🐳 PDFGrabber Docker Launcher"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "   Open Docker Desktop and try again."
    exit 1
fi

# Check if image exists
if ! docker images | grep -q "pdfgrabber-advanced"; then
    echo "📦 First time: building Docker image..."
    echo "   This will take 5-10 minutes..."
    echo ""
    docker-compose build
    echo ""
    echo "✅ Image built successfully!"
    echo ""
fi

# Start PDFGrabber
echo "🚀 Starting PDFGrabber..."
echo ""
docker-compose run --rm pdfgrabber

echo ""
echo "👋 PDFGrabber finished. Your PDFs are in the files/ folder"


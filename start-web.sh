#!/bin/bash
# Start PDFGrabber Web UI
# Opens at http://localhost:6066

set -e

echo "🌐 PDFGrabber Web UI Launcher"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "   Open Docker Desktop and try again."
    exit 1
fi

# Check if images exist, build if not
if ! docker images | grep -q "pdfgrabber.*backend"; then
    echo "📦 First time: building Docker images..."
    echo "   This will take 10-15 minutes..."
    echo ""
    docker-compose -f docker-compose.web.yml build
    echo ""
    echo "✅ Images built successfully!"
    echo ""
fi

# Start services
echo "🚀 Starting PDFGrabber Web UI..."
echo ""
docker-compose -f docker-compose.web.yml up -d

echo ""
echo "✅ PDFGrabber Web UI is running!"
echo ""
echo "🌐 Open your browser at:"
echo "   👉 http://localhost:6066"
echo ""
echo "To stop the service, run:"
echo "   docker-compose -f docker-compose.web.yml down"
echo ""


#!/bin/bash

# ============================================================
# PDFGrabber - Update Script (Linux/macOS)
# ============================================================
# This script:
# 1. Updates code from Git
# 2. Stops Docker containers
# 3. Rebuilds and starts containers
# 4. Opens browser at localhost:6066
# ============================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_step() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

echo ""
echo "============================================================"
echo "  PDFGrabber - Update and Restart"
echo "============================================================"
echo ""

# Check if Git is installed
if ! command -v git &> /dev/null; then
    print_error "[ERROR] Git is not installed"
    echo "Please install Git:"
    echo "  macOS: brew install git"
    echo "  Linux: sudo apt install git"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "[ERROR] Docker is not installed"
    echo "Please install Docker:"
    echo "  macOS: https://www.docker.com/products/docker-desktop/"
    echo "  Linux: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "[ERROR] Docker Compose is not installed"
    echo "Please install Docker Compose"
    exit 1
fi

# Step 1: Git Pull
print_step "[1/4] Updating code from Git..."
echo "============================================================"
if git pull; then
    print_success "✓ Code updated successfully"
else
    print_warning "⚠ Git pull failed"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Update cancelled"
        exit 1
    fi
fi
echo ""

# Step 2: Stop Docker containers
print_step "[2/4] Stopping Docker containers..."
echo "============================================================"
docker-compose -f docker-compose.web.yml down
print_success "✓ Containers stopped"
echo ""

# Step 3: Rebuild and start containers
print_step "[3/4] Rebuilding and starting containers..."
echo "============================================================"
echo "This may take a few minutes..."
if docker-compose -f docker-compose.web.yml up -d --build; then
    print_success "✓ Containers started successfully"
else
    print_error "✗ Failed to start containers"
    echo "Please check if Docker Desktop/daemon is running"
    exit 1
fi
echo ""

# Step 4: Wait for containers to be ready
print_step "[4/4] Waiting for services to be ready..."
echo "============================================================"
sleep 5

# Check if containers are running
if docker ps --filter "name=pdfgrabber" --format "{{.Names}}" | grep -q pdfgrabber; then
    print_success "✓ Containers are running!"
    docker ps --filter "name=pdfgrabber" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    print_warning "⚠ Containers may not be running properly"
    echo "Run 'docker ps' to check container status"
fi
echo ""

echo "============================================================"
echo "  Update Complete!"
echo "============================================================"
echo ""
echo "Opening PDFGrabber Web Interface..."
echo "URL: http://localhost:6066"
echo ""

# Open browser based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open http://localhost:6066
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:6066 &> /dev/null
    elif command -v gnome-open &> /dev/null; then
        gnome-open http://localhost:6066 &> /dev/null
    else
        print_warning "Could not open browser automatically"
        echo "Please open: http://localhost:6066"
    fi
fi

echo ""
echo "============================================================"
echo "  Useful Commands:"
echo "============================================================"
echo "  View logs:         docker-compose -f docker-compose.web.yml logs -f"
echo "  Stop containers:   docker-compose -f docker-compose.web.yml down"
echo "  Restart:           docker-compose -f docker-compose.web.yml restart"
echo "============================================================"
echo ""

# Ask if user wants to see logs
read -p "Show container logs? (y/N): " -t 5 -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "============================================================"
    echo "  Container Logs (Press Ctrl+C to exit):"
    echo "============================================================"
    docker-compose -f docker-compose.web.yml logs -f
fi


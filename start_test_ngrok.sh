#!/bin/bash

# Quick Start Script for ngrok Testing
# THEO Clothing Inventory Management System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/Users/istemamahmed/Desktop/inventory management system"
VENV_DIR="venv"

# Function to display colored output
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Display banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    NGROK TEST LAUNCHER                       ║"
echo "║         THEO Clothing Inventory Management System           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    error "Please run this script from the project directory"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    warning "Virtual environment not found. Creating one..."
    python3 -m venv $VENV_DIR
    success "Virtual environment created"
fi

# Activate virtual environment
log "Activating virtual environment..."
source $VENV_DIR/bin/activate

# Install/update requirements
if [ -f "requirements.txt" ]; then
    log "Installing/updating requirements..."
    pip install -r requirements.txt > /dev/null 2>&1
    success "Requirements installed"
fi

# Check if ngrok binary exists
if [ ! -f "./ngrok" ]; then
    warning "ngrok binary not found in current directory"
    echo ""
    echo "To download ngrok:"
    echo "1. Go to https://ngrok.com/download"
    echo "2. Download the appropriate version for your system"
    echo "3. Extract and place the 'ngrok' binary in this directory"
    echo ""
    read -p "Do you want to continue without ngrok (local testing only)? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    warning "Continuing with local testing only"
fi

# Check ngrok authentication (if ngrok exists)
if [ -f "./ngrok" ]; then
    log "Checking ngrok authentication..."
    if ! ./ngrok config check >/dev/null 2>&1; then
        warning "ngrok is not authenticated"
        echo ""
        echo "For better ngrok features:"
        echo "1. Sign up at https://ngrok.com/"
        echo "2. Get your authtoken from the dashboard"
        echo "3. Run: ./ngrok config add-authtoken YOUR_AUTHTOKEN"
        echo ""
        read -p "Continue without authentication? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        success "ngrok is authenticated"
    fi
fi

# Display options
echo ""
echo -e "${BLUE}Choose testing mode:${NC}"
echo "1. Full ngrok test (with internet access)"
echo "2. Local test only"
echo "3. Run test suite only"
echo ""
read -p "Enter your choice (1-3): " -n 1 -r
echo

case $REPLY in
    1)
        log "Starting full ngrok test environment..."
        python3 run_test_ngrok.py
        ;;
    2)
        log "Starting local test environment..."
        python3 run.py
        ;;
    3)
        log "Running test suite..."
        python3 test_ngrok_setup.py
        ;;
    *)
        error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

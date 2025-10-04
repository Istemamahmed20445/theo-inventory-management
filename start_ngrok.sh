#!/bin/bash

# ngrok Startup Script for THEO Clothing Inventory Management System
# This script starts both the Flask application and ngrok tunnel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
APP_PORT=5003
NGROK_PORT=5003
PROJECT_DIR="/Users/istemamahmed/Desktop/inventory management system"

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
echo "║                NGROK INTERNET ACCESS                        ║"
echo "║         THEO Clothing Inventory Management System          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    error "Please run this script from the project directory"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    error "Virtual environment not found. Please run setup first."
    exit 1
fi

# Check if ngrok is available
if [ ! -f "./ngrok" ]; then
    error "ngrok not found in current directory"
    exit 1
fi

# Check if ngrok is authenticated
log "Checking ngrok authentication..."
if ! ./ngrok config check >/dev/null 2>&1; then
    warning "ngrok is not authenticated. Please set up your authtoken:"
    echo "1. Go to https://ngrok.com/ and sign up for a free account"
    echo "2. Get your authtoken from the dashboard"
    echo "3. Run: ./ngrok config add-authtoken YOUR_AUTHTOKEN"
    echo ""
    read -p "Do you want to continue without authentication? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to cleanup on exit
cleanup() {
    log "Shutting down services..."
    if [ ! -z "$FLASK_PID" ]; then
        kill $FLASK_PID 2>/dev/null || true
    fi
    if [ ! -z "$NGROK_PID" ]; then
        kill $NGROK_PID 2>/dev/null || true
    fi
    success "Services stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start Flask application in background
log "Starting Flask application on port $APP_PORT..."
source venv/bin/activate
python3 run.py &
FLASK_PID=$!

# Wait for Flask to start
log "Waiting for Flask application to start..."
sleep 5

# Check if Flask is running
if ! kill -0 $FLASK_PID 2>/dev/null; then
    error "Failed to start Flask application"
    exit 1
fi

# Start ngrok tunnel
log "Starting ngrok tunnel..."
./ngrok http $NGROK_PORT --log=stdout > ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start
log "Waiting for ngrok to establish tunnel..."
sleep 3

# Get ngrok public URL
log "Getting ngrok public URL..."
sleep 2

# Try to get the URL from ngrok API
NGROK_URL=""
for i in {1..10}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data['tunnels']:
        if tunnel['proto'] == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
" 2>/dev/null)
    
    if [ ! -z "$NGROK_URL" ]; then
        break
    fi
    sleep 1
done

# Display results
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                    NGROK TUNNEL ACTIVE                        ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
success "Flask application is running on port $APP_PORT"
success "ngrok tunnel is active"

if [ ! -z "$NGROK_URL" ]; then
    echo ""
    echo -e "${GREEN}🌐 Internet Access URL:${NC} $NGROK_URL"
    echo -e "${BLUE}📱 Local Access URL:${NC} http://localhost:$APP_PORT"
    echo ""
    echo -e "${YELLOW}Share this URL with anyone to access your inventory system:${NC}"
    echo -e "${PURPLE}$NGROK_URL${NC}"
    echo ""
    echo -e "${BLUE}Default login credentials:${NC}"
    echo -e "Username: ${YELLOW}admin${NC}"
    echo -e "Password: ${YELLOW}admin123${NC}"
    echo ""
    warning "Remember to change the default password for security!"
else
    warning "Could not retrieve ngrok URL automatically"
    echo "Check ngrok.log for details or visit http://localhost:4040"
fi

echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "• View ngrok dashboard: ${YELLOW}open http://localhost:4040${NC}"
echo -e "• View application logs: ${YELLOW}tail -f ngrok.log${NC}"
echo -e "• Stop services: ${YELLOW}Ctrl+C${NC}"
echo ""

# Keep script running
log "Services are running. Press Ctrl+C to stop..."
while true; do
    # Check if processes are still running
    if ! kill -0 $FLASK_PID 2>/dev/null; then
        error "Flask application stopped unexpectedly"
        break
    fi
    if ! kill -0 $NGROK_PID 2>/dev/null; then
        error "ngrok tunnel stopped unexpectedly"
        break
    fi
    sleep 5
done

cleanup

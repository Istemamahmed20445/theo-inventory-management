#!/bin/bash

# Production Deployment Script for THEO Clothing Inventory Management System
# Usage: ./deploy.sh [production|staging]

set -e

# Configuration
ENVIRONMENT=${1:-production}
APP_NAME="theo-inventory"
APP_DIR="/opt/theo-inventory"
BACKUP_DIR="/opt/backups/theo-inventory"
LOG_FILE="/var/log/theo-inventory-deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"
    command -v nginx >/dev/null 2>&1 || error "Nginx is required but not installed"
    command -v certbot >/dev/null 2>&1 || warning "Certbot not found - SSL certificates may need manual setup"
    
    success "All dependencies are available"
}

# Create necessary directories
setup_directories() {
    log "Setting up directories..."
    
    sudo mkdir -p $APP_DIR
    sudo mkdir -p $BACKUP_DIR
    sudo mkdir -p /var/log
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo mkdir -p /etc/systemd/system
    
    # Set proper permissions
    sudo chown -R $USER:$USER $APP_DIR
    sudo chown -R $USER:$USER $BACKUP_DIR
    
    success "Directories created successfully"
}

# Backup current deployment
backup_current() {
    if [ -d "$APP_DIR" ] && [ "$(ls -A $APP_DIR)" ]; then
        log "Creating backup of current deployment..."
        
        BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
        sudo cp -r $APP_DIR $BACKUP_DIR/$BACKUP_NAME
        
        # Keep only last 5 backups
        cd $BACKUP_DIR
        ls -t | tail -n +6 | xargs -r rm -rf
        
        success "Backup created: $BACKUP_NAME"
    fi
}

# Deploy application
deploy_app() {
    log "Deploying application..."
    
    # Copy application files
    cp -r . $APP_DIR/
    cd $APP_DIR
    
    # Create environment file if it doesn't exist
    if [ ! -f .env ]; then
        log "Creating environment file..."
        cat > .env << EOF
# Production Environment Variables
FLASK_ENV=production
SECRET_KEY=$(openssl rand -base64 32)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
EOF
        warning "Please update .env file with your actual Firebase credentials"
    fi
    
    # Build and start services
    log "Building Docker images..."
    docker-compose build --no-cache
    
    log "Starting services..."
    docker-compose up -d
    
    success "Application deployed successfully"
}

# Setup Nginx
setup_nginx() {
    log "Setting up Nginx..."
    
    # Copy Nginx configuration
    sudo cp nginx_production.conf /etc/nginx/sites-available/$APP_NAME
    
    # Update domain name in config
    read -p "Enter your domain name: " DOMAIN_NAME
    sudo sed -i "s/your-domain.com/$DOMAIN_NAME/g" /etc/nginx/sites-available/$APP_NAME
    sudo sed -i "s|/path/to/your/inventory/management/system|$APP_DIR|g" /etc/nginx/sites-available/$APP_NAME
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t || error "Nginx configuration test failed"
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    success "Nginx configured successfully"
}

# Setup SSL with Let's Encrypt
setup_ssl() {
    log "Setting up SSL certificate..."
    
    read -p "Enter your domain name: " DOMAIN_NAME
    read -p "Enter your email address: " EMAIL
    
    # Install Certbot if not available
    if ! command -v certbot >/dev/null 2>&1; then
        log "Installing Certbot..."
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Obtain SSL certificate
    sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive
    
    success "SSL certificate installed successfully"
}

# Setup systemd service
setup_systemd() {
    log "Setting up systemd service..."
    
    # Update service file with correct paths
    sed "s|/path/to/your/inventory/management/system|$APP_DIR|g" theo-inventory.service > /tmp/theo-inventory.service
    sudo cp /tmp/theo-inventory.service /etc/systemd/system/
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable theo-inventory
    
    success "Systemd service configured"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    # Create log rotation configuration
    sudo tee /etc/logrotate.d/theo-inventory > /dev/null << EOF
$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose -f $APP_DIR/docker-compose.yml restart web
    endscript
}
EOF
    
    success "Monitoring configured"
}

# Main deployment function
main() {
    log "Starting deployment for environment: $ENVIRONMENT"
    
    check_dependencies
    setup_directories
    backup_current
    deploy_app
    setup_nginx
    
    # Ask about SSL setup
    read -p "Do you want to setup SSL certificate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi
    
    setup_systemd
    setup_monitoring
    
    success "Deployment completed successfully!"
    log "Your application should be available at: https://your-domain.com"
    log "To check status: docker-compose -f $APP_DIR/docker-compose.yml ps"
    log "To view logs: docker-compose -f $APP_DIR/docker-compose.yml logs -f"
}

# Run main function
main "$@"

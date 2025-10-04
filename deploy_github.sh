#!/bin/bash

# GitHub Corporate Deployment Script for THEO Clothing Inventory Management System
# Usage: ./deploy_github.sh [github-repo-url] [domain] [email]

set -e

# Configuration
GITHUB_REPO=${1:-"https://github.com/your-org/theo-inventory.git"}
DOMAIN=${2:-"inventory.yourcompany.com"}
EMAIL=${3:-"admin@yourcompany.com"}
APP_NAME="theo-inventory"
APP_DIR="/opt/theo-inventory"
BACKUP_DIR="/opt/backups/theo-inventory"
LOG_FILE="/var/log/theo-inventory-github-deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

info() {
    echo -e "${PURPLE}[INFO]${NC} $1" | tee -a $LOG_FILE
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Display GitHub deployment banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                GITHUB CORPORATE DEPLOYMENT                  ║"
echo "║         THEO Clothing Inventory Management System          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log "Starting GitHub corporate deployment"
log "Repository: $GITHUB_REPO"
log "Domain: $DOMAIN"
log "Email: $EMAIL"

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    command -v git >/dev/null 2>&1 || error "Git is required but not installed"
    command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"
    command -v nginx >/dev/null 2>&1 || error "Nginx is required but not installed"
    command -v certbot >/dev/null 2>&1 || warning "Certbot not found - SSL certificates may need manual setup"
    
    success "All dependencies are available"
}

# Create necessary directories
setup_directories() {
    log "Setting up corporate directories..."
    
    sudo mkdir -p $APP_DIR
    sudo mkdir -p $BACKUP_DIR
    sudo mkdir -p /var/log
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo mkdir -p /etc/systemd/system
    sudo mkdir -p /opt/backups
    
    # Set proper permissions
    sudo chown -R $USER:$USER $APP_DIR
    sudo chown -R $USER:$USER $BACKUP_DIR
    sudo chown -R $USER:$USER /opt/backups
    
    success "Corporate directories created successfully"
}

# Clone or update repository
setup_repository() {
    log "Setting up GitHub repository..."
    
    if [ -d "$APP_DIR/.git" ]; then
        log "Repository already exists, updating..."
        cd $APP_DIR
        git pull origin main
    else
        log "Cloning repository from GitHub..."
        git clone $GITHUB_REPO $APP_DIR
        cd $APP_DIR
    fi
    
    # Set up git configuration
    git config --local user.name "Corporate Deploy"
    git config --local user.email "$EMAIL"
    
    success "Repository setup completed"
}

# Backup current deployment
backup_current() {
    if [ -d "$APP_DIR" ] && [ "$(ls -A $APP_DIR 2>/dev/null)" ]; then
        log "Creating backup of current deployment..."
        
        BACKUP_NAME="github-backup-$(date +%Y%m%d-%H%M%S)"
        sudo cp -r $APP_DIR $BACKUP_DIR/$BACKUP_NAME
        
        # Keep only last 10 backups
        cd $BACKUP_DIR
        ls -t | tail -n +11 | xargs -r rm -rf
        
        success "Backup created: $BACKUP_NAME"
    fi
}

# Deploy application
deploy_app() {
    log "Deploying application from GitHub..."
    
    cd $APP_DIR
    
    # Create corporate environment file
    if [ ! -f .env ]; then
        log "Creating corporate environment file..."
        cp env.template .env
        
        # Update environment variables
        sed -i "s/your-super-secret-key-here-change-this-in-production/$(openssl rand -base64 32)/g" .env
        sed -i "s/your-firebase-project-id/your-corporate-project-id/g" .env
        sed -i "s/your-firebase-project-id.appspot.com/your-corporate-project.appspot.com/g" .env
        sed -i "s/admin@theoclothing.com/$EMAIL/g" .env
        sed -i "s/localhost:5003/$DOMAIN/g" .env
        
        warning "Please update .env file with your actual Firebase credentials"
    fi
    
    # Build and start services
    log "Building Docker images..."
    docker-compose build --no-cache
    
    log "Starting corporate services..."
    docker-compose up -d
    
    success "Application deployed successfully from GitHub"
}

# Setup corporate Nginx
setup_nginx() {
    log "Setting up corporate Nginx configuration..."
    
    # Copy Nginx configuration
    sudo cp nginx_production.conf /etc/nginx/sites-available/$APP_NAME
    
    # Update domain name in config
    sudo sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/$APP_NAME
    sudo sed -i "s|/path/to/your/inventory/management/system|$APP_DIR|g" /etc/nginx/sites-available/$APP_NAME
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t || error "Nginx configuration test failed"
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    success "Corporate Nginx configured successfully"
}

# Setup SSL with Let's Encrypt
setup_ssl() {
    log "Setting up corporate SSL certificate..."
    
    # Install Certbot if not available
    if ! command -v certbot >/dev/null 2>&1; then
        log "Installing Certbot..."
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Obtain SSL certificate
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive
    
    # Setup auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    success "Corporate SSL certificate installed successfully"
}

# Setup corporate firewall
setup_firewall() {
    log "Setting up corporate firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80
    sudo ufw allow 443
    
    # Deny direct access to application
    sudo ufw deny 8000
    
    # Show status
    sudo ufw status
    
    success "Corporate firewall configured successfully"
}

# Setup systemd service
setup_systemd() {
    log "Setting up corporate systemd service..."
    
    # Update service file with correct paths
    sed "s|/path/to/your/inventory/management/system|$APP_DIR|g" theo-inventory.service > /tmp/theo-inventory.service
    sudo cp /tmp/theo-inventory.service /etc/systemd/system/
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable theo-inventory
    
    success "Corporate systemd service configured"
}

# Setup GitHub Actions secrets
setup_github_secrets() {
    log "Setting up GitHub Actions secrets..."
    
    info "To complete GitHub Actions setup, add these secrets to your repository:"
    info "1. Go to your GitHub repository settings"
    info "2. Navigate to 'Secrets and variables' > 'Actions'"
    info "3. Add the following secrets:"
    info "   - PRODUCTION_HOST: $(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')"
    info "   - PRODUCTION_USER: $USER"
    info "   - PRODUCTION_SSH_KEY: (Your private SSH key)"
    info "   - PRODUCTION_PORT: 22"
    info "   - SLACK_WEBHOOK: (Optional - for notifications)"
    
    success "GitHub Actions secrets information provided"
}

# Setup corporate monitoring
setup_monitoring() {
    log "Setting up corporate monitoring..."
    
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
    
    # Create corporate backup script
    sudo tee /opt/backups/github-backup.sh > /dev/null << EOF
#!/bin/bash
# Corporate GitHub backup script

BACKUP_DIR="/opt/backups/theo-inventory"
DATE=\$(date +%Y%m%d_%H%M%S)
APP_DIR="/opt/theo-inventory"

# Create backup
tar -czf \$BACKUP_DIR/github-backup_\$DATE.tar.gz \$APP_DIR

# Keep only last 30 days
find \$BACKUP_DIR -name "github-backup_*.tar.gz" -mtime +30 -delete

echo "GitHub backup completed: \$DATE"
EOF
    
    sudo chmod +x /opt/backups/github-backup.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/backups/github-backup.sh") | crontab -
    
    success "Corporate monitoring configured"
}

# Display GitHub deployment summary
display_summary() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                GITHUB DEPLOYMENT COMPLETE                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    info "Your corporate inventory system is now deployed from GitHub:"
    info "🌐 Application: https://$DOMAIN"
    info "📧 Admin email: $EMAIL"
    info "📁 Application directory: $APP_DIR"
    info "💾 Backup directory: $BACKUP_DIR"
    info "🔗 GitHub repository: $GITHUB_REPO"
    
    echo ""
    info "Next steps:"
    info "1. Update Firebase credentials in .env file"
    info "2. Set up GitHub Actions secrets for automated deployment"
    info "3. Access the system and create corporate users"
    info "4. Configure company branding and settings"
    info "5. Set up monitoring alerts"
    info "6. Train your team on the system"
    
    echo ""
    info "Useful commands:"
    info "• Check status: docker-compose -f $APP_DIR/docker-compose.yml ps"
    info "• View logs: docker-compose -f $APP_DIR/docker-compose.yml logs -f"
    info "• Update from GitHub: cd $APP_DIR && git pull origin main"
    info "• Restart: docker-compose -f $APP_DIR/docker-compose.yml restart"
    info "• Backup: /opt/backups/github-backup.sh"
    
    echo ""
    warning "Important: Update your .env file with actual Firebase credentials!"
    warning "Set up GitHub Actions secrets for automated deployment!"
    warning "Default admin login: admin/admin123 (change immediately)"
}

# Main deployment function
main() {
    log "Starting GitHub corporate deployment"
    
    check_dependencies
    setup_directories
    backup_current
    setup_repository
    deploy_app
    setup_nginx
    
    # Ask about SSL setup
    read -p "Do you want to setup SSL certificate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi
    
    setup_firewall
    setup_systemd
    setup_github_secrets
    setup_monitoring
    
    display_summary
    
    success "GitHub corporate deployment completed successfully!"
}

# Run main function
main "$@"

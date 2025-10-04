#!/bin/bash

# Internet Deployment Script for THEO Clothing Inventory Management System
# Usage: ./deploy_internet.sh [domain] [email] [server-ip]

set -e

# Configuration
DOMAIN=${1:-"inventory.yourcompany.com"}
EMAIL=${2:-"admin@yourcompany.com"}
SERVER_IP=${3:-$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")}
APP_NAME="theo-inventory"
APP_DIR="/opt/theo-inventory"
BACKUP_DIR="/opt/backups/theo-inventory"
LOG_FILE="/var/log/theo-inventory-internet-deploy.log"

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

# Display internet deployment banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                INTERNET DEPLOYMENT                         ║"
echo "║         THEO Clothing Inventory Management System          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log "Starting internet deployment"
log "Domain: $DOMAIN"
log "Email: $EMAIL"
log "Server IP: $SERVER_IP"

# Check if required tools are installed
check_dependencies() {
    log "Checking dependencies..."
    
    command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"
    command -v nginx >/dev/null 2>&1 || error "Nginx is required but not installed"
    command -v certbot >/dev/null 2>&1 || warning "Certbot not found - SSL certificates may need manual setup"
    command -v curl >/dev/null 2>&1 || error "curl is required but not installed"
    
    success "All dependencies are available"
}

# Create necessary directories
setup_directories() {
    log "Setting up internet deployment directories..."
    
    sudo mkdir -p $APP_DIR
    sudo mkdir -p $BACKUP_DIR
    sudo mkdir -p /var/log
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo mkdir -p /etc/systemd/system
    sudo mkdir -p /opt/backups
    sudo mkdir -p /etc/nginx/snippets
    
    # Set proper permissions
    sudo chown -R $USER:$USER $APP_DIR
    sudo chown -R $USER:$USER $BACKUP_DIR
    sudo chown -R $USER:$USER /opt/backups
    
    success "Internet deployment directories created successfully"
}

# Setup internet firewall
setup_internet_firewall() {
    log "Setting up internet firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH (change port for security)
    sudo ufw allow 2222/tcp
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow application port (internal only)
    sudo ufw allow from 127.0.0.1 to any port 8000
    
    # Deny direct access to application from internet
    sudo ufw deny 8000/tcp
    
    # Show firewall status
    sudo ufw status verbose
    
    success "Internet firewall configured successfully"
}

# Setup SSL configuration
setup_ssl_config() {
    log "Setting up SSL configuration..."
    
    # Create SSL parameters
    sudo tee /etc/nginx/snippets/ssl-params.conf > /dev/null << 'EOF'
# SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1;
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
EOF
    
    success "SSL configuration created successfully"
}

# Setup internet Nginx configuration
setup_internet_nginx() {
    log "Setting up internet Nginx configuration..."
    
    # Create rate limiting zones
    sudo tee /etc/nginx/conf.d/rate-limiting.conf > /dev/null << 'EOF'
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=1r/s;
EOF
    
    # Create internet Nginx configuration
    sudo tee /etc/nginx/sites-available/inventory-internet > /dev/null << EOF
# Upstream for load balancing
upstream inventory_backend {
    server 127.0.0.1:8000;
    # Add more servers for load balancing
    # server 127.0.0.1:8001;
    # server 127.0.0.1:8002;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/nginx/snippets/ssl-params.conf;

    # Security headers
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https://storage.googleapis.com; connect-src 'self';";

    # Rate limiting
    limit_req zone=login burst=5 nodelay;
    limit_req zone=api burst=20 nodelay;
    limit_req zone=general burst=10 nodelay;

    # Static files
    location /static/ {
        alias $APP_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
        gzip on;
        gzip_types text/css application/javascript image/svg+xml;
    }

    # Health check
    location /health {
        proxy_pass http://inventory_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        access_log off;
    }

    # Main application
    location / {
        proxy_pass http://inventory_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        proxy_buffering off;
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
    }

    # Error pages
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/inventory-internet /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t || error "Nginx configuration test failed"
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    success "Internet Nginx configured successfully"
}

# Setup SSL certificate
setup_ssl_certificate() {
    log "Setting up SSL certificate..."
    
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
    
    success "SSL certificate installed successfully"
}

# Deploy application
deploy_application() {
    log "Deploying application for internet access..."
    
    # Copy application files
    cp -r . $APP_DIR/
    cd $APP_DIR
    
    # Create internet environment file
    if [ ! -f .env ]; then
        log "Creating internet environment file..."
        cat > .env << EOF
# Internet Environment Variables
FLASK_ENV=production
SECRET_KEY=$(openssl rand -base64 32)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_STORAGE_BUCKET=your-firebase-project.appspot.com
COMPANY_NAME=Your Company Name
COMPANY_EMAIL=$EMAIL
DOMAIN=$DOMAIN
SERVER_IP=$SERVER_IP
EOF
        warning "Please update .env file with your actual Firebase credentials"
    fi
    
    # Build and start services
    log "Building Docker images..."
    docker-compose build --no-cache
    
    log "Starting internet services..."
    docker-compose up -d
    
    success "Application deployed successfully for internet access"
}

# Setup systemd service
setup_systemd_service() {
    log "Setting up systemd service..."
    
    # Create systemd service
    sudo tee /etc/systemd/system/theo-inventory.service > /dev/null << EOF
[Unit]
Description=THEO Clothing Inventory Management System
After=network.target

[Service]
Type=exec
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
Restart=always
RestartSec=10
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable theo-inventory
    
    success "Systemd service configured successfully"
}

# Setup monitoring and security
setup_monitoring_security() {
    log "Setting up monitoring and security..."
    
    # Install fail2ban
    sudo apt install fail2ban -y
    
    # Configure fail2ban
    sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 3
EOF
    
    # Start fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    
    # Create log rotation
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
    
    success "Monitoring and security configured successfully"
}

# Setup backup strategy
setup_backup_strategy() {
    log "Setting up backup strategy..."
    
    # Create backup script
    sudo tee /opt/backups/internet-backup.sh > /dev/null << EOF
#!/bin/bash
# Internet deployment backup script

BACKUP_DIR="/opt/backups/theo-inventory"
DATE=\$(date +%Y%m%d_%H%M%S)
APP_DIR="$APP_DIR"

# Create backup
tar -czf \$BACKUP_DIR/internet-backup_\$DATE.tar.gz \$APP_DIR

# Keep only last 30 days
find \$BACKUP_DIR -name "internet-backup_*.tar.gz" -mtime +30 -delete

echo "Internet backup completed: \$DATE"
EOF
    
    sudo chmod +x /opt/backups/internet-backup.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/backups/internet-backup.sh") | crontab -
    
    success "Backup strategy configured successfully"
}

# Display internet deployment summary
display_summary() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                INTERNET DEPLOYMENT COMPLETE                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    info "Your inventory system is now accessible from the internet:"
    info "🌐 Main Application: https://$DOMAIN"
    info "📧 Admin email: $EMAIL"
    info "🖥️  Server IP: $SERVER_IP"
    info "📁 Application directory: $APP_DIR"
    info "💾 Backup directory: $BACKUP_DIR"
    
    echo ""
    info "Internet access features:"
    info "✅ HTTPS/SSL encryption for security"
    info "✅ Global internet access from anywhere"
    info "✅ Mobile-optimized responsive design"
    info "✅ Rate limiting and DDoS protection"
    info "✅ Firewall protection and security"
    info "✅ Automated backups and monitoring"
    
    echo ""
    info "Next steps:"
    info "1. Update Firebase credentials in .env file"
    info "2. Configure DNS to point $DOMAIN to $SERVER_IP"
    info "3. Test internet access from different locations"
    info "4. Set up monitoring alerts"
    info "5. Train your team on internet access"
    
    echo ""
    info "Useful commands:"
    info "• Check status: docker-compose -f $APP_DIR/docker-compose.yml ps"
    info "• View logs: docker-compose -f $APP_DIR/docker-compose.yml logs -f"
    info "• Restart: docker-compose -f $APP_DIR/docker-compose.yml restart"
    info "• Backup: /opt/backups/internet-backup.sh"
    info "• SSL renewal: sudo certbot renew"
    
    echo ""
    warning "Important: Update your .env file with actual Firebase credentials!"
    warning "Configure DNS to point $DOMAIN to $SERVER_IP"
    warning "Default admin login: admin/admin123 (change immediately)"
    
    echo ""
    info "Access URLs:"
    info "• Main Application: https://$DOMAIN"
    info "• Admin Panel: https://$DOMAIN/admin"
    info "• Health Check: https://$DOMAIN/health"
    info "• Mobile Access: https://$DOMAIN (responsive design)"
}

# Main deployment function
main() {
    log "Starting internet deployment"
    
    check_dependencies
    setup_directories
    setup_internet_firewall
    setup_ssl_config
    setup_internet_nginx
    
    # Ask about SSL setup
    read -p "Do you want to setup SSL certificate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl_certificate
    fi
    
    deploy_application
    setup_systemd_service
    setup_monitoring_security
    setup_backup_strategy
    
    display_summary
    
    success "Internet deployment completed successfully!"
}

# Run main function
main "$@"

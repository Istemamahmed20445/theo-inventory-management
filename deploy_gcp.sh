#!/bin/bash

# Google Cloud Platform Deployment Script
# THEO Clothing Inventory Management System

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
REGION="us-central1"
SERVICE_NAME="theo-inventory"
FIREBASE_PROJECT_ID=""
FIREBASE_STORAGE_BUCKET=""
SECRET_KEY=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    if ! command_exists gcloud; then
        print_error "Google Cloud CLI not found. Please install it first:"
        echo "curl https://sdk.cloud.google.com | bash"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    if [ ! -f "firebase-service-account.json" ]; then
        print_error "Firebase service account file not found."
        print_warning "Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'"
        exit 1
    fi
    
    print_success "Prerequisites validated successfully"
}

# Function to get configuration from user
get_configuration() {
    print_status "Getting deployment configuration..."
    
    if [ -z "$PROJECT_ID" ]; then
        read -p "Enter your Google Cloud Project ID: " PROJECT_ID
    fi
    
    if [ -z "$FIREBASE_PROJECT_ID" ]; then
        read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID
    fi
    
    if [ -z "$FIREBASE_STORAGE_BUCKET" ]; then
        FIREBASE_STORAGE_BUCKET="${FIREBASE_PROJECT_ID}.appspot.com"
        print_warning "Using default storage bucket: $FIREBASE_STORAGE_BUCKET"
    fi
    
    if [ -z "$SECRET_KEY" ]; then
        SECRET_KEY=$(openssl rand -hex 32)
        print_success "Generated new secret key"
    fi
    
    print_status "Configuration:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Service Name: $SERVICE_NAME"
    echo "  Firebase Project: $FIREBASE_PROJECT_ID"
    echo "  Storage Bucket: $FIREBASE_STORAGE_BUCKET"
}

# Function to setup Google Cloud
setup_gcloud() {
    print_status "Setting up Google Cloud..."
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Enable required APIs
    print_status "Enabling required APIs..."
    gcloud services enable run.googleapis.com
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable artifactregistry.googleapis.com
    gcloud services enable logging.googleapis.com
    gcloud services enable monitoring.googleapis.com
    gcloud services enable secretmanager.googleapis.com
    
    # Configure Docker authentication
    gcloud auth configure-docker
    
    print_success "Google Cloud setup completed"
}

# Function to create secrets
create_secrets() {
    print_status "Creating secrets..."
    
    # Create Firebase service account secret
    if ! gcloud secrets describe firebase-service-account >/dev/null 2>&1; then
        gcloud secrets create firebase-service-account --data-file=firebase-service-account.json
        print_success "Created Firebase service account secret"
    else
        print_warning "Firebase service account secret already exists"
    fi
    
    # Create application secret key
    if ! gcloud secrets describe app-secret-key >/dev/null 2>&1; then
        echo -n "$SECRET_KEY" | gcloud secrets create app-secret-key --data-file=-
        print_success "Created application secret key"
    else
        print_warning "Application secret key already exists"
    fi
}

# Function to build and push container
build_and_push() {
    print_status "Building and pushing container..."
    
    # Use the GCP-optimized Dockerfile
    docker build -f Dockerfile.gcp -t gcr.io/$PROJECT_ID/$SERVICE_NAME .
    
    # Push to Google Container Registry
    docker push gcr.io/$PROJECT_ID/$SERVICE_NAME
    
    print_success "Container built and pushed successfully"
}

# Function to deploy to Cloud Run
deploy_cloud_run() {
    print_status "Deploying to Google Cloud Run..."
    
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --memory 1Gi \
        --cpu 1 \
        --min-instances 0 \
        --max-instances 10 \
        --port 8080 \
        --timeout 300 \
        --concurrency 80 \
        --set-env-vars FLASK_ENV=production \
        --set-env-vars FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
        --set-env-vars FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
        --set-env-vars SESSION_COOKIE_SECURE=true \
        --set-secrets="FIREBASE_CREDENTIALS=firebase-service-account:latest,SECRET_KEY=app-secret-key:latest"
    
    print_success "Deployment to Cloud Run completed"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Get the service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")
    
    # Create uptime check
    if ! gcloud alpha monitoring uptime-checks list --filter="displayName:THEO Inventory Health Check" --format="value(name)" | grep -q "uptimeCheck"; then
        gcloud alpha monitoring uptime-checks create http \
            --display-name="THEO Inventory Health Check" \
            --hostname=$(echo $SERVICE_URL | sed 's|https://||') \
            --path="/health" \
            --check-interval=60s \
            --timeout=10s \
            --period=300s
        print_success "Created uptime check"
    else
        print_warning "Uptime check already exists"
    fi
}

# Function to display deployment information
show_deployment_info() {
    print_success "Deployment completed successfully!"
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")
    
    echo ""
    echo "🎉 Your application is now running 24/7 on Google Cloud Run!"
    echo ""
    echo "📱 Application URL: $SERVICE_URL"
    echo "🔍 Health Check: $SERVICE_URL/health"
    echo "📊 Monitoring: https://console.cloud.google.com/monitoring"
    echo "📝 Logs: https://console.cloud.google.com/logs"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Test your application at the URL above"
    echo "   2. Set up a custom domain (optional)"
    echo "   3. Configure SSL certificate (if using custom domain)"
    echo "   4. Set up automated backups"
    echo ""
    echo "💰 Estimated monthly cost: $0-10 (pay-per-use pricing)"
    echo ""
}

# Function to cleanup on error
cleanup_on_error() {
    print_error "Deployment failed. Cleaning up..."
    # Add cleanup commands here if needed
    exit 1
}

# Main deployment function
main() {
    echo "🚀 THEO Inventory Management System - Google Cloud Deployment"
    echo "=============================================================="
    echo ""
    
    # Set error trap
    trap cleanup_on_error ERR
    
    # Run deployment steps
    validate_prerequisites
    get_configuration
    setup_gcloud
    create_secrets
    build_and_push
    deploy_cloud_run
    setup_monitoring
    show_deployment_info
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

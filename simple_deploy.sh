#!/bin/bash

# Simple Google Cloud Run Deployment Script
# THEO Clothing Inventory Management System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 THEO Inventory - Simple Cloud Run Deployment${NC}"
echo "=================================================="
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker Desktop first.${NC}"
    exit 1
fi

# Check if docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Check if firebase service account exists
if [ ! -f "firebase-service-account.json" ]; then
    echo -e "${RED}❌ Firebase service account file not found.${NC}"
    echo -e "${YELLOW}Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are met!${NC}"
echo ""

# Get configuration from user
echo -e "${BLUE}⚙️  Configuration Setup${NC}"
echo ""

read -p "Enter your Google Cloud Project ID: " PROJECT_ID
read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID

# Set default values
SERVICE_NAME="theo-inventory"
REGION="us-central1"
FIREBASE_STORAGE_BUCKET="${FIREBASE_PROJECT_ID}.appspot.com"

echo ""
echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Service: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Firebase Project: $FIREBASE_PROJECT_ID"
echo "  Storage Bucket: $FIREBASE_STORAGE_BUCKET"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 Setting up Google Cloud...${NC}"

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

# Configure Docker
echo "Configuring Docker..."
gcloud auth configure-docker

echo -e "${GREEN}✅ Google Cloud setup completed${NC}"
echo ""

echo -e "${BLUE}🏗️  Building and deploying application...${NC}"

# Build the container
echo "Building container..."
docker build -f Dockerfile.gcp -t gcr.io/$PROJECT_ID/$SERVICE_NAME .

# Push to Google Container Registry
echo "Pushing container to registry..."
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
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
  --set-env-vars SESSION_COOKIE_SECURE=true

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📱 Your application is now live:${NC}"
echo "   URL: $SERVICE_URL"
echo "   Health Check: $SERVICE_URL/health"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Test your application at the URL above"
echo "2. Upload your firebase-service-account.json as a secret (optional)"
echo "3. Set up monitoring and alerts (optional)"
echo "4. Configure a custom domain (optional)"
echo ""
echo -e "${BLUE}💰 Estimated monthly cost: $0-10 (pay-per-use pricing)${NC}"
echo ""
echo -e "${GREEN}🚀 Your inventory management system is now running 24/7 on Google Cloud Run!${NC}"

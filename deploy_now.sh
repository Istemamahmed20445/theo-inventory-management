#!/bin/bash

# Full Google Cloud Run Deployment Script
# THEO Clothing Inventory Management System

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 THEO Inventory - Full Cloud Run Deployment${NC}"
echo "==============================================="

# Project configuration
PROJECT_ID="spry-scope-473614-v8"
FIREBASE_PROJECT_ID="inventory-3098f"
SERVICE_NAME="theo-inventory"
REGION="us-central1"
FIREBASE_STORAGE_BUCKET="inventory-3098f.appspot.com"

echo -e "${BLUE}📋 Deployment Configuration:${NC}"
echo "  Google Cloud Project: $PROJECT_ID"
echo "  Firebase Project: $FIREBASE_PROJECT_ID"
echo "  Service Name: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Storage Bucket: $FIREBASE_STORAGE_BUCKET"
echo ""

# Check if authenticated
echo -e "${BLUE}🔐 Checking authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo -e "${YELLOW}⚠️  Not authenticated. Please run: gcloud auth login${NC}"
    echo -e "${YELLOW}This will open a browser window for authentication.${NC}"
    echo ""
    read -p "Press Enter after you've completed authentication..."
fi

# Set project
echo -e "${BLUE}⚙️  Setting up project...${NC}"
gcloud config set project $PROJECT_ID

# Enable APIs
echo -e "${BLUE}📡 Enabling required APIs...${NC}"
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable secretmanager.googleapis.com

echo -e "${GREEN}✅ APIs enabled successfully${NC}"

# Configure Docker
echo -e "${BLUE}🐳 Configuring Docker for Google Cloud...${NC}"
gcloud auth configure-docker

echo -e "${GREEN}✅ Docker configured successfully${NC}"

# Build container
echo -e "${BLUE}🏗️  Building container...${NC}"
docker build -f Dockerfile.gcp -t gcr.io/$PROJECT_ID/$SERVICE_NAME .

echo -e "${GREEN}✅ Container built successfully${NC}"

# Push container
echo -e "${BLUE}📤 Pushing container to Google Container Registry...${NC}"
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME

echo -e "${GREEN}✅ Container pushed successfully${NC}"

# Deploy to Cloud Run
echo -e "${BLUE}🚀 Deploying to Google Cloud Run...${NC}"
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

echo -e "${GREEN}✅ Deployment to Cloud Run completed${NC}"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}📱 Your application is now live:${NC}"
echo "   🌐 URL: $SERVICE_URL"
echo "   🔍 Health Check: $SERVICE_URL/health"
echo ""
echo -e "${BLUE}🚀 Features enabled:${NC}"
echo "   ✅ 24/7 Availability"
echo "   ✅ Auto-scaling (0-10 instances)"
echo "   ✅ Global CDN"
echo "   ✅ HTTPS secure connection"
echo "   ✅ Pay-per-use pricing"
echo ""
echo -e "${BLUE}💰 Estimated monthly cost: $0-10${NC}"
echo ""
echo -e "${GREEN}🎯 Next steps:${NC}"
echo "1. Test your application at the URL above"
echo "2. Set up Firebase secrets (optional)"
echo "3. Configure monitoring (optional)"
echo "4. Set up custom domain (optional)"
echo ""
echo -e "${GREEN}🚀 Your inventory management system is now running 24/7 on Google Cloud Run!${NC}"

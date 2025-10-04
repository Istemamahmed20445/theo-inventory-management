#!/bin/bash

# Quick Google Cloud Run Deployment Script
# THEO Clothing Inventory Management System

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Quick Google Cloud Run Deployment${NC}"
echo "=================================="

# Get project ID
read -p "Enter your Google Cloud Project ID: " PROJECT_ID
read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID

# Set variables
SERVICE_NAME="theo-inventory"
REGION="us-central1"
FIREBASE_STORAGE_BUCKET="${FIREBASE_PROJECT_ID}.appspot.com"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Service: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Firebase Project: $FIREBASE_PROJECT_ID"
echo ""

# Set project and enable APIs
echo -e "${BLUE}🔧 Setting up Google Cloud...${NC}"
gcloud config set project $PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com

# Build and deploy
echo -e "${BLUE}🏗️  Building and deploying...${NC}"
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

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
  --set-env-vars FLASK_ENV=production \
  --set-env-vars FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
  --set-env-vars FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
  --set-env-vars SESSION_COOKIE_SECURE=true

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")

echo ""
echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo "📱 Application URL: $SERVICE_URL"
echo "🔍 Health Check: $SERVICE_URL/health"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Upload your firebase-service-account.json file"
echo "2. Test your application at the URL above"
echo "3. Set up monitoring and alerts"
echo ""
echo -e "${BLUE}💰 Estimated cost: $0-10/month (pay-per-use)${NC}"

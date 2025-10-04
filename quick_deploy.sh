#!/bin/bash

# Quick Google Cloud Run Deployment Script
# Run this AFTER you've authenticated with gcloud auth login

set -e

echo "🚀 THEO Inventory - Quick Cloud Run Deployment"
echo "=============================================="

# Get configuration
read -p "Enter your Google Cloud Project ID: " PROJECT_ID
read -p "Enter your Firebase Project ID: " FIREBASE_PROJECT_ID

# Set variables
SERVICE_NAME="theo-inventory"
REGION="us-central1"
FIREBASE_STORAGE_BUCKET="${FIREBASE_PROJECT_ID}.appspot.com"

echo ""
echo "📋 Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Service: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Firebase Project: $FIREBASE_PROJECT_ID"
echo ""

# Set project
echo "🔧 Setting up project..."
gcloud config set project $PROJECT_ID

# Enable APIs
echo "📡 Enabling required APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

# Configure Docker
echo "🐳 Configuring Docker..."
gcloud auth configure-docker

# Build and push
echo "🏗️  Building container..."
docker build -f Dockerfile.gcp -t gcr.io/$PROJECT_ID/$SERVICE_NAME .

echo "📤 Pushing container..."
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy
echo "🚀 Deploying to Cloud Run..."
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

# Get URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")

echo ""
echo "🎉 Deployment successful!"
echo "📱 Application URL: $SERVICE_URL"
echo "🔍 Health Check: $SERVICE_URL/health"
echo ""
echo "💰 Estimated monthly cost: $0-10 (pay-per-use)"
echo "🚀 Your app is now running 24/7 on Google Cloud Run!"

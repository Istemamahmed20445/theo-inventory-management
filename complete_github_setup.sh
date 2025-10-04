#!/bin/bash

echo "🚀 Complete GitHub Setup for Theo's Inventory Management System"
echo "=============================================================="
echo ""

echo "📋 INSTRUCTIONS:"
echo "1. Go to: https://github.com/new"
echo "2. Repository name: theo-inventory-management"
echo "3. Description: Modern Inventory Management System with Firebase integration"
echo "4. Make it PUBLIC"
echo "5. DON'T initialize with README/gitignore/license"
echo "6. Click 'Create repository'"
echo ""
echo "7. After creating, copy your repository URL (it will look like:"
echo "   https://github.com/YOUR_USERNAME/theo-inventory-management.git)"
echo ""

read -p "📝 Enter your GitHub repository URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "❌ No URL provided. Exiting."
    exit 1
fi

echo ""
echo "🔄 Setting up remote repository..."

# Add remote origin
git remote add origin "$REPO_URL"

if [ $? -eq 0 ]; then
    echo "✅ Remote origin added successfully"
else
    echo "❌ Failed to add remote origin"
    exit 1
fi

echo ""
echo "🚀 Pushing to GitHub..."

# Push to GitHub
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Your inventory management system is now on GitHub!"
    echo "📍 Repository URL: $REPO_URL"
    echo ""
    echo "📋 NEXT STEPS FOR RAILWAY DEPLOYMENT:"
    echo "1. Go to https://railway.app/"
    echo "2. Sign up with your GitHub account"
    echo "3. Click 'New Project' → 'Deploy from GitHub repo'"
    echo "4. Select your repository: theo-inventory-management"
    echo "5. Railway will automatically detect your Flask app"
    echo "6. Configure environment variables:"
    echo "   - FLASK_ENV=production"
    echo "   - FLASK_DEBUG=False"
    echo "   - SECRET_KEY=your-random-secret-key"
    echo "   - FIREBASE_PROJECT_ID=inventory-3098f"
    echo "   - FIREBASE_STORAGE_BUCKET=inventory-3098f-p2f4t"
    echo "7. Upload firebase-service-account.json or set Firebase env vars"
    echo "8. Deploy and get your live URL!"
    echo ""
    echo "🔗 Your app will be available at: https://theoclothinginventory.railway.app"
else
    echo "❌ Failed to push to GitHub"
    echo "Please check your repository URL and try again"
fi

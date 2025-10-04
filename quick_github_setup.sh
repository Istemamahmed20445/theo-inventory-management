#!/bin/bash

# Quick GitHub Setup Script for Inventory Management System
echo "🚀 Setting up GitHub repository for your inventory management system"
echo "=================================================================="

# Change to project directory
cd "$(dirname "$0")"
echo "📁 Working in: $(pwd)"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install git first."
    echo "Visit: https://git-scm.com/downloads"
    exit 1
fi

echo "✅ Git is installed"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gh
        else
            echo "❌ Please install Homebrew first, then run: brew install gh"
            exit 1
        fi
    else
        echo "❌ Please install GitHub CLI manually from: https://cli.github.com/"
        exit 1
    fi
fi

echo "✅ GitHub CLI is available"

# Initialize git repository
if [ ! -d ".git" ]; then
    echo "🔄 Initializing git repository..."
    git init
    echo "✅ Git repository initialized"
else
    echo "📁 Git repository already exists"
fi

# Add all files
echo "🔄 Adding all files to git..."
git add .
echo "✅ All files added to git"

# Create initial commit
echo "🔄 Creating initial commit..."
git commit -m "Initial commit: Theo's Inventory Management System

- Complete Flask inventory management system
- Firebase integration for data storage
- Modern responsive UI with Bootstrap
- Product, customer, and sales management
- Barcode scanning capabilities
- Excel import/export functionality
- Ready for Railway deployment"

echo "✅ Initial commit created"

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "🔄 Logging in to GitHub..."
    echo "This will open your browser to authenticate with GitHub"
    gh auth login
fi

echo "✅ GitHub authentication confirmed"

# Create GitHub repository
echo "🔄 Creating GitHub repository..."
REPO_NAME="theo-inventory-management"
REPO_DESCRIPTION="Modern Inventory Management System with Firebase integration for clothing and retail businesses"

gh repo create $REPO_NAME \
    --public \
    --description "$REPO_DESCRIPTION" \
    --source=. \
    --remote=origin \
    --push

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESS! Your inventory management system is now on GitHub!"
    echo "📍 Repository URL: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
    echo ""
    echo "📋 Next Steps for Railway Deployment:"
    echo "1. Go to https://railway.app/"
    echo "2. Sign up with your GitHub account"
    echo "3. Click 'New Project' → 'Deploy from GitHub repo'"
    echo "4. Select your repository: $REPO_NAME"
    echo "5. Configure environment variables:"
    echo "   - FLASK_ENV=production"
    echo "   - FLASK_DEBUG=False"
    echo "   - SECRET_KEY=your-random-secret-key"
    echo "   - FIREBASE_PROJECT_ID=inventory-3098f"
    echo "   - FIREBASE_STORAGE_BUCKET=inventory-3098f-p2f4t"
    echo "6. Upload firebase-service-account.json or set Firebase env vars"
    echo "7. Deploy and get your live URL!"
    echo ""
    echo "🔗 Your app will be available at: https://theoclothinginventory.railway.app"
else
    echo "❌ Failed to create GitHub repository"
    echo "You can manually create one at: https://github.com/new"
    echo "Then run: git remote add origin <your-repo-url>"
    echo "Then run: git push -u origin main"
fi

echo ""
echo "🎯 Your inventory management system is ready for deployment!"

#!/bin/bash

echo "🚀 Pushing Theo's Inventory Management System to GitHub"
echo "======================================================"
echo ""

echo "📍 Repository: https://github.com/Istemamahmed20445/theo-inventory-management.git"
echo ""

echo "🔐 GitHub Authentication Required"
echo "You have a few options to authenticate:"
echo ""
echo "Option 1: Personal Access Token (Recommended)"
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
echo "3. Give it a name: 'Theo Inventory Management'"
echo "4. Select scopes: repo (full control)"
echo "5. Click 'Generate token'"
echo "6. Copy the token"
echo ""

echo "Option 2: GitHub CLI (if available)"
echo "1. Install GitHub CLI: brew install gh"
echo "2. Run: gh auth login"
echo ""

echo "Option 3: SSH Key (if you have one set up)"
echo "1. Use SSH URL instead of HTTPS"
echo ""

read -p "Choose option (1, 2, or 3): " OPTION

case $OPTION in
    1)
        echo ""
        echo "🔑 Using Personal Access Token"
        read -p "Enter your GitHub username (istemamahmed20445): " USERNAME
        read -s -p "Enter your Personal Access Token: " TOKEN
        echo ""
        
        if [ -z "$TOKEN" ]; then
            echo "❌ No token provided"
            exit 1
        fi
        
        # Update remote URL with token
        git remote set-url origin https://$USERNAME:$TOKEN@github.com/Istemamahmed20445/theo-inventory-management.git
        
        echo "🔄 Pushing to GitHub..."
        git push -u origin main
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "🎉 SUCCESS! Your inventory management system is now on GitHub!"
            echo "📍 Repository: https://github.com/Istemamahmed20445/theo-inventory-management"
            echo ""
            echo "📋 NEXT STEPS FOR RAILWAY DEPLOYMENT:"
            echo "1. Go to https://railway.app/"
            echo "2. Sign up with your GitHub account"
            echo "3. Click 'New Project' → 'Deploy from GitHub repo'"
            echo "4. Select: theo-inventory-management"
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
            echo "❌ Failed to push to GitHub. Please check your credentials."
        fi
        ;;
    2)
        echo ""
        echo "🔧 Using GitHub CLI"
        if command -v gh &> /dev/null; then
            gh auth login
            git push -u origin main
        else
            echo "❌ GitHub CLI not installed. Please install it first:"
            echo "   brew install gh"
        fi
        ;;
    3)
        echo ""
        echo "🔑 Using SSH Key"
        git remote set-url origin git@github.com:Istemamahmed20445/theo-inventory-management.git
        git push -u origin main
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

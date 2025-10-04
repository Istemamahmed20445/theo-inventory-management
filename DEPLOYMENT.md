# THEO Inventory Management System - Render Deployment Guide

## 🚀 Quick Deploy to Render

### Step 1: Connect GitHub Repository
1. Go to [render.com](https://render.com)
2. Sign up/Login with your GitHub account
3. Click "New +" → "Web Service"
4. Connect your GitHub repository: `theo-inventory-management`

### Step 2: Configure Service Settings
- **Name**: `theo-inventory-management`
- **Environment**: `Python 3`
- **Branch**: `main`
- **Root Directory**: Leave empty
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `gunicorn app:app`

### Step 3: Environment Variables
Add these environment variables in Render dashboard:

```
FLASK_ENV=production
SECRET_KEY=<generate-a-secure-secret-key>
FIREBASE_PROJECT_ID=<your-firebase-project-id>
FIREBASE_STORAGE_BUCKET=<your-firebase-storage-bucket>
```

### Step 4: Firebase Setup
1. Download your Firebase service account JSON file
2. Convert it to base64: `base64 -i firebase-service-account.json`
3. Add as environment variable: `FIREBASE_CREDENTIALS=<base64-encoded-json>`

### Step 5: Deploy
Click "Create Web Service" and wait for deployment to complete.

## 📋 Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FLASK_ENV` | Flask environment | `production` |
| `SECRET_KEY` | Flask secret key | `your-secret-key` |
| `FIREBASE_PROJECT_ID` | Firebase project ID | `your-project-id` |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket | `your-project-id.appspot.com` |
| `FIREBASE_CREDENTIALS` | Base64 encoded service account JSON | `base64-encoded-json` |

## 🔧 Local Development

1. Copy `.env.template` to `.env`
2. Fill in your environment variables
3. Install dependencies: `pip install -r requirements.txt`
4. Run: `python run.py`

## 📝 Notes

- The app will automatically use the PORT environment variable provided by Render
- File uploads will work with Render's ephemeral file system
- For persistent file storage, consider using Firebase Storage or AWS S3
- The free tier includes 750 hours/month (enough for development)
- For 24/7 uptime, upgrade to a paid plan ($7/month)

## 🆘 Troubleshooting

- Check Render logs for deployment issues
- Ensure all environment variables are set
- Verify Firebase service account credentials
- Check that requirements.txt includes all dependencies

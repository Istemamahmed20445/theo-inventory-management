# 🏪 Theo's Inventory Management System - Local Development

## 🚀 **Quick Start**

### **Option 1: Interactive Script (Recommended)**
```bash
python3 run_local.py
```
This will give you options to run locally or with ngrok.

### **Option 2: Direct Commands**

**Run Locally Only:**
```bash
python app.py
```
Access at: http://localhost:5000

**Run with ngrok (Access from anywhere):**
```bash
# Terminal 1: Start Flask app
python app.py

# Terminal 2: Start ngrok tunnel
ngrok http 5000
```

## 🔧 **Setup Requirements**

### **1. Python Environment**
```bash
# Create virtual environment (if not exists)
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### **2. Firebase Setup**
- Place your `firebase-service-account.json` in the project root
- The app will automatically connect to Firebase

### **3. ngrok Setup (Optional)**
```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Sign up for free account at https://ngrok.com/
# Get your auth token and run:
ngrok config add-authtoken YOUR_TOKEN
```

## 🌐 **Access Your App**

### **Local Access:**
- **URL:** http://localhost:5000
- **Login:** admin / admin123

### **Public Access (with ngrok):**
- **URL:** https://[random].ngrok.io (shown in ngrok output)
- **Login:** admin / admin123

## 📱 **Features Available**

✅ **Product Management** - Add, edit, delete products with images  
✅ **Customer Management** - Track customer information  
✅ **Sales Tracking** - Record and monitor sales  
✅ **Barcode Scanning** - Quick product lookup  
✅ **Excel Import/Export** - Bulk operations  
✅ **Categories & Variants** - Organize by colors, sizes  
✅ **Modern UI** - Responsive design  
✅ **Firebase Integration** - Cloud storage  

## 🔧 **Configuration**

### **Environment Variables (Optional)**
Create a `.env` file:
```env
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key
FIREBASE_PROJECT_ID=inventory-3098f
FIREBASE_STORAGE_BUCKET=inventory-3098f-p2f4t
```

### **Firebase Configuration**
The app automatically loads Firebase credentials from:
- `firebase-service-account.json` file, or
- Environment variables (if file not found)

## 🛠️ **Development Tips**

### **View Logs:**
```bash
# Flask app logs
tail -f flask_output.log

# ngrok logs
tail -f ngrok.log
```

### **Reset Database:**
- Delete Firebase collections or restart Firebase emulator
- App will recreate necessary collections

### **Update Dependencies:**
```bash
pip install -r requirements.txt --upgrade
```

## 📞 **Troubleshooting**

### **Port Already in Use:**
```bash
# Kill process on port 5000
lsof -ti:5000 | xargs kill -9
```

### **Firebase Connection Issues:**
- Check `firebase-service-account.json` exists
- Verify Firebase project settings
- Check internet connection

### **ngrok Issues:**
- Verify ngrok is installed: `ngrok version`
- Check auth token: `ngrok config check`
- Try different port: `ngrok http 8000`

## 🎯 **Ready to Start?**

**Just run:**
```bash
python3 run_local.py
```

**Choose your preferred option and start developing!** 🚀

---

**Happy coding!** 🎉

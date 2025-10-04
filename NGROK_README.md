# 🌐 ngrok Internet Access Setup

This guide will help you set up internet access for your THEO Clothing Inventory Management System using ngrok.

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
```bash
cd "/Users/istemamahmed/Desktop/inventory management system"
source venv/bin/activate
python3 run_with_ngrok.py
```

### Option 2: Shell Script
```bash
cd "/Users/istemamahmed/Desktop/inventory management system"
./start_ngrok.sh
```

## 📋 Prerequisites

1. **ngrok Account**: Sign up for a free account at [ngrok.com](https://ngrok.com/)
2. **Authtoken**: Get your authtoken from the ngrok dashboard
3. **Python Environment**: Ensure your virtual environment is activated

## 🔧 Setup Steps

### Step 1: Get ngrok Authtoken
1. Go to [ngrok.com](https://ngrok.com/) and sign up
2. Navigate to your dashboard
3. Copy your authtoken
4. Run: `./ngrok config add-authtoken YOUR_AUTHTOKEN`

### Step 2: Start the Application
Choose one of the following methods:

#### Method A: Python Script (Recommended)
```bash
python3 run_with_ngrok.py
```

#### Method B: Shell Script
```bash
./start_ngrok.sh
```

#### Method C: Manual Setup
```bash
# Terminal 1: Start Flask app
source venv/bin/activate
python3 run.py

# Terminal 2: Start ngrok
./ngrok http 5003
```

## 🌍 Access Your Application

Once started, you'll see output like this:

```
╔══════════════════════════════════════════════════════════════╗
║                    NGROK TUNNEL ACTIVE                        ║
╚══════════════════════════════════════════════════════════════╝

✅ Flask application is running on port 5003
✅ ngrok tunnel is active

🌐 Internet Access URL: https://abc123.ngrok.io
📱 Local Access URL: http://localhost:5003

Share this URL with anyone to access your inventory system:
https://abc123.ngrok.io

🔐 Default Login Credentials:
Username: admin
Password: admin123
```

## 🛠️ Useful Commands

- **View ngrok dashboard**: `open http://localhost:4040`
- **Stop services**: `Ctrl+C`
- **Check logs**: `tail -f ngrok.log`

## 🔒 Security Notes

1. **Change default password** immediately after first login
2. **Use HTTPS** (ngrok provides this automatically)
3. **Monitor access** through the ngrok dashboard
4. **Limit access** to trusted users only

## 🐛 Troubleshooting

### ngrok not starting
- Check if ngrok is authenticated: `./ngrok config check`
- Verify authtoken: `./ngrok config add-authtoken YOUR_AUTHTOKEN`

### Can't access the application
- Check if Flask is running on port 5003
- Verify ngrok tunnel is active at http://localhost:4040
- Check firewall settings

### URL not working
- ngrok URLs change on restart (free plan)
- Check ngrok dashboard for current URL
- Ensure both Flask and ngrok are running

## 📱 Mobile Access

Your application is fully responsive and works on:
- Desktop computers
- Tablets
- Mobile phones
- Any device with internet access

## 🎯 Features Available via Internet

- ✅ Product management
- ✅ Inventory tracking
- ✅ Sales recording
- ✅ Customer management
- ✅ Barcode scanning
- ✅ Excel import/export
- ✅ Real-time updates
- ✅ Mobile-optimized interface

## 🔄 Restarting Services

To restart with a new ngrok URL:
1. Stop the current session (`Ctrl+C`)
2. Start again with `python3 run_with_ngrok.py`
3. Share the new URL

## 📞 Support

If you encounter issues:
1. Check the ngrok dashboard at http://localhost:4040
2. Review the logs in `ngrok.log`
3. Ensure all dependencies are installed
4. Verify your internet connection

---

**Your inventory system is now accessible worldwide! 🌍**

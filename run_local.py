#!/usr/bin/env python3
"""
Local Development Server for Theo's Inventory Management System
This script starts the Flask app locally and optionally with ngrok
"""

import os
import subprocess
import sys
import time
from pathlib import Path

def check_ngrok():
    """Check if ngrok is available"""
    try:
        result = subprocess.run(["ngrok", "version"], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ ngrok is installed")
            return True
    except FileNotFoundError:
        pass
    
    print("⚠️  ngrok not found")
    return False

def start_flask_app():
    """Start the Flask application"""
    print("🚀 Starting Theo's Inventory Management System...")
    print("📍 Local URL: http://localhost:5000")
    print("🔐 Login: admin / admin123")
    print()
    
    # Start Flask app
    os.system("python app.py")

def start_with_ngrok():
    """Start Flask app and ngrok tunnel"""
    if not check_ngrok():
        print("❌ ngrok not available. Starting local server only...")
        start_flask_app()
        return
    
    print("🚀 Starting Flask app with ngrok tunnel...")
    
    # Start Flask app in background
    flask_process = subprocess.Popen([sys.executable, "app.py"])
    
    # Wait a moment for Flask to start
    time.sleep(3)
    
    print("🌐 Starting ngrok tunnel...")
    print("📱 Your app will be accessible from anywhere!")
    print()
    
    # Start ngrok
    try:
        os.system("ngrok http 5000")
    except KeyboardInterrupt:
        print("\n🛑 Stopping servers...")
        flask_process.terminate()
        flask_process.wait()

def main():
    """Main function"""
    print("🏪 Theo's Inventory Management System - Local Development")
    print("=" * 60)
    print()
    
    print("Choose an option:")
    print("1. Run locally only (http://localhost:5000)")
    print("2. Run with ngrok tunnel (accessible from anywhere)")
    print("3. Exit")
    print()
    
    choice = input("Enter your choice (1-3): ").strip()
    
    if choice == "1":
        start_flask_app()
    elif choice == "2":
        start_with_ngrok()
    elif choice == "3":
        print("👋 Goodbye!")
        sys.exit(0)
    else:
        print("❌ Invalid choice. Please run the script again.")
        sys.exit(1)

if __name__ == "__main__":
    main()

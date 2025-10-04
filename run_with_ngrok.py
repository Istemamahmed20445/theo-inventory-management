#!/usr/bin/env python3
"""
Run script with ngrok integration for THEO Clothing Inventory Management System
This script starts both the Flask application and ngrok tunnel automatically
"""

import os
import sys
import subprocess
import time
import signal
import threading
import requests
import json
from app import app

class NgrokManager:
    def __init__(self, port=5003):
        self.port = port
        self.ngrok_process = None
        self.public_url = None
        self.ngrok_dir = os.path.dirname(os.path.abspath(__file__))
        self.ngrok_binary = os.path.join(self.ngrok_dir, 'ngrok')
        
    def start_ngrok(self):
        """Start ngrok tunnel"""
        if not os.path.exists(self.ngrok_binary):
            print("❌ ngrok binary not found. Please ensure ngrok is in the project directory.")
            return False
            
        try:
            # Start ngrok process
            self.ngrok_process = subprocess.Popen(
                [self.ngrok_binary, 'http', str(self.port), '--log=stdout'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Wait for ngrok to start
            time.sleep(3)
            
            # Get public URL from ngrok API
            self.public_url = self.get_public_url()
            return True
            
        except Exception as e:
            print(f"❌ Failed to start ngrok: {e}")
            return False
    
    def get_public_url(self):
        """Get the public URL from ngrok API"""
        try:
            response = requests.get('http://localhost:4040/api/tunnels', timeout=5)
            if response.status_code == 200:
                data = response.json()
                for tunnel in data.get('tunnels', []):
                    if tunnel.get('proto') == 'https':
                        return tunnel.get('public_url')
        except Exception as e:
            print(f"⚠️  Could not get ngrok URL: {e}")
        return None
    
    def stop_ngrok(self):
        """Stop ngrok process"""
        if self.ngrok_process:
            self.ngrok_process.terminate()
            self.ngrok_process.wait()
            self.ngrok_process = None

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    print("\n🛑 Shutting down services...")
    if 'ngrok_manager' in globals():
        ngrok_manager.stop_ngrok()
    sys.exit(0)

def check_dependencies():
    """Check if required dependencies are available"""
    # Check if Firebase service account file exists
    if not os.path.exists('firebase-service-account.json'):
        print("❌ Error: Firebase service account file not found!")
        print("Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'")
        print("You can get this file from: https://console.firebase.google.com/project/YOUR_PROJECT_ID/settings/serviceaccounts/adminsdk")
        return False
    
    # Check if upload directory exists
    upload_dir = 'static/uploads'
    if not os.path.exists(upload_dir):
        os.makedirs(upload_dir)
        print(f"📁 Created upload directory: {upload_dir}")
    
    return True

def get_local_ip():
    """Get local IP address"""
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "localhost"

def main():
    """Main function to start the application with ngrok"""
    # Set up signal handler
    signal.signal(signal.SIGINT, signal_handler)
    
    print("🚀 Starting THEO CLOTHING INVENTORY System with ngrok...")
    print("=" * 60)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Get local IP
    local_ip = get_local_ip()
    
    # Initialize ngrok manager
    global ngrok_manager
    ngrok_manager = NgrokManager()
    
    # Start ngrok
    print("🌐 Starting ngrok tunnel...")
    if not ngrok_manager.start_ngrok():
        print("⚠️  ngrok failed to start. Running without internet access...")
        ngrok_manager = None
    else:
        print("✅ ngrok tunnel established")
    
    # Display access information
    print("\n" + "=" * 60)
    print("📱 ACCESS INFORMATION")
    print("=" * 60)
    print(f"🏠 Local Access:     http://localhost:5003")
    print(f"🌐 Network Access:   http://{local_ip}:5003")
    
    if ngrok_manager and ngrok_manager.public_url:
        print(f"🌍 Internet Access:  {ngrok_manager.public_url}")
        print("\n🎉 Your inventory system is now accessible worldwide!")
        print(f"📤 Share this URL: {ngrok_manager.public_url}")
    else:
        print("⚠️  Internet access not available (ngrok not running)")
    
    print("\n🔐 Default Login Credentials:")
    print("   Username: admin")
    print("   Password: admin123")
    print("\n⚠️  Remember to change the default password for security!")
    
    print("\n" + "=" * 60)
    print("🛠️  USEFUL COMMANDS")
    print("=" * 60)
    print("• View ngrok dashboard: open http://localhost:4040")
    print("• Stop services: Ctrl+C")
    print("• Check logs: tail -f logs/app.log")
    
    print("\n" + "=" * 60)
    print("🚀 Starting Flask application...")
    print("Press Ctrl+C to stop the server")
    print("=" * 60)
    
    try:
        # Start Flask application
        app.run(debug=True, host='0.0.0.0', port=5003)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
    finally:
        if ngrok_manager:
            ngrok_manager.stop_ngrok()

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Test Runner with ngrok integration for THEO Clothing Inventory Management System
This script is specifically designed for testing with ngrok tunnel
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

class NgrokTestManager:
    def __init__(self, port=5003):
        self.port = port
        self.ngrok_process = None
        self.public_url = None
        self.ngrok_dir = os.path.dirname(os.path.abspath(__file__))
        self.ngrok_binary = os.path.join(self.ngrok_dir, 'ngrok')
        self.test_mode = True
        
    def start_ngrok(self):
        """Start ngrok tunnel for testing"""
        if not os.path.exists(self.ngrok_binary):
            print("❌ ngrok binary not found. Please ensure ngrok is in the project directory.")
            print("💡 Download ngrok from: https://ngrok.com/download")
            return False
            
        try:
            # Start ngrok process with test-friendly settings
            cmd = [
                self.ngrok_binary, 
                'http', 
                str(self.port), 
                '--log=stdout',
                '--log-level=info'
            ]
            
            # Add config file if it exists
            config_file = os.path.join(self.ngrok_dir, 'ngrok.yml')
            if os.path.exists(config_file):
                cmd.extend(['--config', config_file])
            
            self.ngrok_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Wait for ngrok to start
            print("🔄 Starting ngrok tunnel...")
            time.sleep(4)
            
            # Get public URL from ngrok API
            self.public_url = self.get_public_url()
            return self.public_url is not None
            
        except Exception as e:
            print(f"❌ Failed to start ngrok: {e}")
            return False
    
    def get_public_url(self):
        """Get the public URL from ngrok API"""
        max_retries = 10
        for attempt in range(max_retries):
            try:
                response = requests.get('http://localhost:4040/api/tunnels', timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    for tunnel in data.get('tunnels', []):
                        if tunnel.get('proto') == 'https':
                            return tunnel.get('public_url')
                        elif tunnel.get('proto') == 'http':
                            # Convert http to https for better testing
                            http_url = tunnel.get('public_url')
                            if http_url:
                                return http_url.replace('http://', 'https://')
            except Exception as e:
                if attempt < max_retries - 1:
                    print(f"⏳ Waiting for ngrok to be ready... (attempt {attempt + 1}/{max_retries})")
                    time.sleep(2)
                else:
                    print(f"⚠️  Could not get ngrok URL after {max_retries} attempts: {e}")
        return None
    
    def stop_ngrok(self):
        """Stop ngrok process"""
        if self.ngrok_process:
            try:
                self.ngrok_process.terminate()
                self.ngrok_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.ngrok_process.kill()
            self.ngrok_process = None
            print("🛑 ngrok tunnel stopped")

def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully"""
    print("\n🛑 Shutting down test environment...")
    if 'ngrok_manager' in globals():
        ngrok_manager.stop_ngrok()
    sys.exit(0)

def check_test_dependencies():
    """Check if required dependencies are available for testing"""
    issues = []
    
    # Check if Firebase service account file exists
    if not os.path.exists('firebase-service-account.json'):
        issues.append("❌ Firebase service account file not found!")
        issues.append("   Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'")
        issues.append("   Get it from: https://console.firebase.google.com/project/YOUR_PROJECT_ID/settings/serviceaccounts/adminsdk")
    
    # Check if upload directory exists
    upload_dir = 'static/uploads'
    if not os.path.exists(upload_dir):
        os.makedirs(upload_dir)
        print(f"📁 Created upload directory: {upload_dir}")
    
    # Check if ngrok binary exists
    ngrok_binary = './ngrok'
    if not os.path.exists(ngrok_binary):
        issues.append("❌ ngrok binary not found!")
        issues.append("   Download from: https://ngrok.com/download")
        issues.append("   Extract and place 'ngrok' in the project directory")
    
    if issues:
        print("\n".join(issues))
        return False
    
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

def display_test_info(ngrok_manager, local_ip):
    """Display comprehensive test information"""
    print("\n" + "=" * 70)
    print("🧪 TEST ENVIRONMENT - NGROK INTEGRATION")
    print("=" * 70)
    
    # Access URLs
    print("\n📱 ACCESS URLS:")
    print(f"   🏠 Local:      http://localhost:5003")
    print(f"   🌐 Network:    http://{local_ip}:5003")
    
    if ngrok_manager and hasattr(ngrok_manager, 'public_url') and ngrok_manager.public_url:
        print(f"   🌍 Internet:   {ngrok_manager.public_url}")
        print(f"\n🎉 Your test environment is accessible worldwide!")
        print(f"📤 Test URL: {ngrok_manager.public_url}")
    else:
        print("   ⚠️  Internet access not available")
    
    # Test credentials
    print(f"\n🔐 TEST CREDENTIALS:")
    print(f"   Username: admin")
    print(f"   Password: admin123")
    
    # Testing tools
    print(f"\n🛠️  TESTING TOOLS:")
    print(f"   • ngrok Dashboard:  http://localhost:4040")
    if ngrok_manager and hasattr(ngrok_manager, 'public_url') and ngrok_manager.public_url:
        print(f"   • API Endpoint:     {ngrok_manager.public_url}/api")
        print(f"   • Health Check:     {ngrok_manager.public_url}/health")
    else:
        print(f"   • API Endpoint:     http://localhost:5003/api")
        print(f"   • Health Check:     http://localhost:5003/health")
    
    # Test scenarios
    print(f"\n🧪 SUGGESTED TEST SCENARIOS:")
    print(f"   1. Login functionality")
    print(f"   2. Product CRUD operations")
    print(f"   3. Image upload/download")
    print(f"   4. Barcode scanning")
    print(f"   5. Excel import/export")
    print(f"   6. Mobile responsiveness")
    
    print(f"\n📊 MONITORING:")
    print(f"   • View logs: tail -f logs/app.log")
    print(f"   • ngrok logs: tail -f ngrok.log")
    print(f"   • Stop test: Ctrl+C")
    
    print("=" * 70)

def main():
    """Main function to start the test environment with ngrok"""
    # Set up signal handler
    signal.signal(signal.SIGINT, signal_handler)
    
    print("🧪 Starting TEST ENVIRONMENT with ngrok...")
    print("🚀 THEO CLOTHING INVENTORY - Testing Mode")
    
    # Check dependencies
    if not check_test_dependencies():
        print("\n❌ Test environment setup incomplete. Please fix the issues above.")
        sys.exit(1)
    
    # Get local IP
    local_ip = get_local_ip()
    
    # Initialize ngrok manager
    global ngrok_manager
    ngrok_manager = NgrokTestManager()
    
    # Start ngrok
    print("\n🌐 Establishing ngrok tunnel for testing...")
    ngrok_success = ngrok_manager.start_ngrok()
    
    if not ngrok_success:
        print("⚠️  ngrok failed to start. Running in local-only test mode...")
        ngrok_manager = None
    else:
        print("✅ ngrok tunnel established successfully")
    
    # Display test information
    display_test_info(ngrok_manager, local_ip)
    
    # Set test environment variables
    os.environ['FLASK_ENV'] = 'testing'
    os.environ['TESTING'] = 'true'
    
    try:
        # Start Flask application in test mode
        print(f"\n🚀 Starting Flask application in TEST MODE...")
        print(f"🔄 Server starting on port 5003...")
        print(f"⏳ Please wait for the server to be ready...")
        
        # Configure app for testing
        app.config['TESTING'] = True
        app.config['DEBUG'] = True
        
        # Start the application
        app.run(debug=True, host='0.0.0.0', port=5003, use_reloader=False)
        
    except KeyboardInterrupt:
        print("\n🛑 Test environment stopped by user")
    except Exception as e:
        print(f"❌ Error starting test environment: {e}")
    finally:
        if ngrok_manager:
            ngrok_manager.stop_ngrok()
        print("🧪 Test environment cleanup completed")

if __name__ == '__main__':
    main()

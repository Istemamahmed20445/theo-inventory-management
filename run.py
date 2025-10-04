#!/usr/bin/env python3
"""
Run script for the Garment Inventory Management System
"""

import os
import sys
from app import app

if __name__ == '__main__':
    # Check if Firebase service account file exists
    if not os.path.exists('firebase-service-account.json'):
        print("Error: Firebase service account file not found!")
        print("Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'")
        print("You can get this file from: https://console.firebase.google.com/project/YOUR_PROJECT_ID/settings/serviceaccounts/adminsdk")
        sys.exit(1)
    
    # Check if upload directory exists
    upload_dir = 'static/uploads'
    if not os.path.exists(upload_dir):
        os.makedirs(upload_dir)
        print(f"Created upload directory: {upload_dir}")
    
    # Get local IP address
    import socket
    def get_local_ip():
        try:
            # Connect to a remote server to get local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return "localhost"
    
    local_ip = get_local_ip()
    
    # Run the application
    print("Starting THEO CLOTHING INVENTORY System...")
    print("=" * 50)
    print("Access URLs:")
    print(f"  Local:     http://localhost:5003")
    print(f"  Network:   http://{local_ip}:5003")
    print("=" * 50)
    print("Press Ctrl+C to stop the server")
    
    try:
        app.run(debug=True, host='0.0.0.0', port=5003)
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

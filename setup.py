#!/usr/bin/env python3
"""
Setup script for the Garment Inventory Management System
"""

import os
import sys
import subprocess
import json
from pathlib import Path

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required")
        print(f"Current version: {sys.version}")
        sys.exit(1)
    print(f"✓ Python version: {sys.version.split()[0]}")

def install_dependencies():
    """Install required Python packages"""
    print("Installing dependencies...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✓ Dependencies installed successfully")
    except subprocess.CalledProcessError as e:
        print(f"Error installing dependencies: {e}")
        sys.exit(1)

def create_directories():
    """Create necessary directories"""
    directories = [
        "static/uploads",
        "static/css",
        "static/js",
        "templates",
        "logs"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"✓ Created directory: {directory}")

def check_firebase_config():
    """Check Firebase configuration"""
    firebase_file = "firebase-service-account.json"
    if not os.path.exists(firebase_file):
        print(f"⚠ Warning: {firebase_file} not found")
        print("Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'")
        print("You can get this file from: https://console.firebase.google.com/project/YOUR_PROJECT_ID/settings/serviceaccounts/adminsdk")
        return False
    
    try:
        with open(firebase_file, 'r') as f:
            config = json.load(f)
        
        required_fields = ['project_id', 'private_key', 'client_email']
        missing_fields = [field for field in required_fields if field not in config or not config[field]]
        
        if missing_fields:
            print(f"⚠ Warning: Missing or empty fields in {firebase_file}: {missing_fields}")
            return False
        
        print("✓ Firebase configuration file found and valid")
        return True
    except json.JSONDecodeError:
        print(f"⚠ Warning: Invalid JSON in {firebase_file}")
        return False

def create_default_admin():
    """Create default admin user"""
    print("Creating default admin user...")
    # This would typically create a default admin user in the database
    # For now, we'll just print instructions
    print("After running the application, you can create an admin user through the admin panel")
    print("Default admin credentials will be created on first run")

def main():
    """Main setup function"""
    print("=" * 50)
    print("Garment Inventory Management System Setup")
    print("=" * 50)
    
    # Check Python version
    check_python_version()
    
    # Create directories
    create_directories()
    
    # Install dependencies
    install_dependencies()
    
    # Check Firebase configuration
    firebase_ok = check_firebase_config()
    
    # Create default admin
    create_default_admin()
    
    print("\n" + "=" * 50)
    print("Setup completed!")
    print("=" * 50)
    
    if not firebase_ok:
        print("\n⚠ Important: Please configure Firebase before running the application")
        print("1. Download your Firebase service account JSON file")
        print("2. Save it as 'firebase-service-account.json'")
        print("3. Update the storage bucket name in app.py")
    
    print("\nTo run the application:")
    print("python run.py")
    print("\nOr:")
    print("python app.py")
    
    print("\nAccess the application at: http://localhost:5000")

if __name__ == "__main__":
    main()

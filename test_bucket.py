#!/usr/bin/env python3
"""
Test script to check Firebase Storage bucket status
"""

import firebase_admin
from firebase_admin import credentials, storage
import os

def test_bucket():
    try:
        # Initialize Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate("firebase-service-account.json")
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'inventory-3098f-p2f4t'
            })
        
        # Get the bucket
        bucket = storage.bucket()
        
        # Test if bucket exists by trying to list files
        blobs = list(bucket.list_blobs(max_results=1))
        print("✅ SUCCESS: Firebase Storage bucket is working!")
        print(f"Bucket name: {bucket.name}")
        print(f"Bucket location: {bucket.location}")
        print(f"Number of files: {len(blobs)}")
        
        return True
        
    except Exception as e:
        print("❌ ERROR: Firebase Storage bucket is NOT working!")
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Firebase Storage bucket...")
    test_bucket()

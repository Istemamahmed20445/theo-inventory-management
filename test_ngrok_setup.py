#!/usr/bin/env python3
"""
Test script to verify ngrok setup for THEO Clothing Inventory Management System
This script performs basic connectivity and functionality tests
"""

import requests
import time
import json
import sys
import os
from urllib.parse import urljoin

class NgrokTester:
    def __init__(self, base_url=None):
        self.base_url = base_url or self.get_ngrok_url()
        self.session = requests.Session()
        self.test_results = []
        
    def get_ngrok_url(self):
        """Get ngrok URL from the API"""
        try:
            response = requests.get('http://localhost:4040/api/tunnels', timeout=5)
            if response.status_code == 200:
                data = response.json()
                for tunnel in data.get('tunnels', []):
                    if tunnel.get('proto') == 'https':
                        return tunnel.get('public_url')
            return 'http://localhost:5003'  # Fallback to local
        except:
            return 'http://localhost:5003'  # Fallback to local
    
    def log_test(self, test_name, success, message="", details=None):
        """Log test results"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}: {message}")
        
        self.test_results.append({
            'test': test_name,
            'success': success,
            'message': message,
            'details': details
        })
        
        if details and not success:
            print(f"   Details: {details}")
    
    def test_basic_connectivity(self):
        """Test basic connectivity to the application"""
        try:
            response = self.session.get(self.base_url, timeout=10)
            success = response.status_code == 200
            message = f"Status: {response.status_code}"
            self.log_test("Basic Connectivity", success, message)
            return success
        except Exception as e:
            self.log_test("Basic Connectivity", False, "Connection failed", str(e))
            return False
    
    def test_login_page(self):
        """Test login page accessibility"""
        try:
            login_url = urljoin(self.base_url, '/login')
            response = self.session.get(login_url, timeout=10)
            success = response.status_code == 200 and 'login' in response.text.lower()
            message = f"Login page accessible (Status: {response.status_code})"
            self.log_test("Login Page", success, message)
            return success
        except Exception as e:
            self.log_test("Login Page", False, "Failed to access login", str(e))
            return False
    
    def test_static_files(self):
        """Test static file serving"""
        try:
            css_url = urljoin(self.base_url, '/static/css/style.css')
            response = self.session.get(css_url, timeout=10)
            success = response.status_code == 200
            message = f"CSS file accessible (Status: {response.status_code})"
            self.log_test("Static Files", success, message)
            return success
        except Exception as e:
            self.log_test("Static Files", False, "Failed to access static files", str(e))
            return False
    
    def test_api_health(self):
        """Test API health endpoint if available"""
        try:
            # Try common health check endpoints
            health_endpoints = ['/health', '/api/health', '/status']
            
            for endpoint in health_endpoints:
                try:
                    health_url = urljoin(self.base_url, endpoint)
                    response = self.session.get(health_url, timeout=5)
                    if response.status_code == 200:
                        self.log_test("API Health", True, f"Health check available at {endpoint}")
                        return True
                except:
                    continue
            
            # If no health endpoint, test a basic API call
            dashboard_url = urljoin(self.base_url, '/dashboard')
            response = self.session.get(dashboard_url, timeout=10)
            # Dashboard should redirect to login if not authenticated
            success = response.status_code in [200, 302, 401]
            message = f"Dashboard endpoint responsive (Status: {response.status_code})"
            self.log_test("API Health", success, message)
            return success
            
        except Exception as e:
            self.log_test("API Health", False, "API not responsive", str(e))
            return False
    
    def test_mobile_responsiveness(self):
        """Test mobile user agent response"""
        try:
            mobile_headers = {
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15'
            }
            response = self.session.get(self.base_url, headers=mobile_headers, timeout=10)
            success = response.status_code == 200
            message = f"Mobile user agent handled (Status: {response.status_code})"
            self.log_test("Mobile Responsiveness", success, message)
            return success
        except Exception as e:
            self.log_test("Mobile Responsiveness", False, "Mobile test failed", str(e))
            return False
    
    def test_ngrok_features(self):
        """Test ngrok-specific features"""
        if 'ngrok' not in self.base_url:
            self.log_test("ngrok Features", True, "Running locally (ngrok features not applicable)")
            return True
            
        try:
            # Test HTTPS redirect
            http_url = self.base_url.replace('https://', 'http://')
            response = self.session.get(http_url, timeout=10, allow_redirects=False)
            
            # ngrok usually redirects HTTP to HTTPS
            success = response.status_code in [301, 302, 200]
            message = f"HTTP handling (Status: {response.status_code})"
            self.log_test("ngrok Features", success, message)
            return success
        except Exception as e:
            self.log_test("ngrok Features", False, "ngrok feature test failed", str(e))
            return False
    
    def run_all_tests(self):
        """Run all tests"""
        print("🧪 Starting ngrok Test Suite")
        print("=" * 50)
        print(f"🌐 Testing URL: {self.base_url}")
        print("=" * 50)
        
        tests = [
            self.test_basic_connectivity,
            self.test_login_page,
            self.test_static_files,
            self.test_api_health,
            self.test_mobile_responsiveness,
            self.test_ngrok_features
        ]
        
        passed = 0
        total = len(tests)
        
        for test in tests:
            if test():
                passed += 1
            time.sleep(1)  # Brief pause between tests
        
        print("\n" + "=" * 50)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 50)
        print(f"✅ Passed: {passed}/{total}")
        print(f"❌ Failed: {total - passed}/{total}")
        
        if passed == total:
            print("🎉 All tests passed! Your ngrok setup is working correctly.")
        else:
            print("⚠️  Some tests failed. Check the details above.")
        
        return passed == total

def main():
    """Main function"""
    print("🚀 THEO Clothing Inventory - ngrok Test Suite")
    
    # Check if ngrok is running
    try:
        response = requests.get('http://localhost:4040/api/tunnels', timeout=5)
        if response.status_code == 200:
            data = response.json()
            tunnels = data.get('tunnels', [])
            if tunnels:
                print(f"✅ ngrok is running with {len(tunnels)} tunnel(s)")
            else:
                print("⚠️  ngrok is running but no tunnels found")
        else:
            print("⚠️  ngrok API not accessible")
    except:
        print("❌ ngrok doesn't appear to be running")
        print("💡 Start ngrok first: python run_test_ngrok.py")
        
        # Ask if user wants to test locally
        try:
            choice = input("\nTest locally instead? (y/n): ").lower()
            if choice != 'y':
                sys.exit(1)
        except KeyboardInterrupt:
            sys.exit(1)
    
    # Run tests
    tester = NgrokTester()
    success = tester.run_all_tests()
    
    if not success:
        sys.exit(1)

if __name__ == '__main__':
    main()

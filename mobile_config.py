"""
Mobile and Internet Configuration for THEO Clothing Inventory Management System
This module provides mobile-optimized settings and internet access configurations
"""

import os
from flask import request, session
from functools import wraps

class MobileConfig:
    """Mobile and internet configuration settings"""
    
    # Mobile detection
    MOBILE_USER_AGENTS = [
        'Mobile', 'Android', 'iPhone', 'iPad', 'iPod', 'BlackBerry', 
        'Windows Phone', 'Opera Mini', 'IEMobile', 'Mobile Safari'
    ]
    
    # Internet access settings
    INTERNET_ACCESS = True
    MOBILE_OPTIMIZED = True
    RESPONSIVE_DESIGN = True
    
    # Performance settings for internet
    CACHE_TIMEOUT = 300  # 5 minutes
    SESSION_TIMEOUT = 3600  # 1 hour
    MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
    
    # Security settings for internet
    RATE_LIMIT_ENABLED = True
    MAX_REQUESTS_PER_MINUTE = 60
    MAX_REQUESTS_PER_HOUR = 1000
    
    # Mobile-specific settings
    MOBILE_CACHE_TIMEOUT = 600  # 10 minutes
    MOBILE_SESSION_TIMEOUT = 7200  # 2 hours
    MOBILE_MAX_UPLOAD_SIZE = 5 * 1024 * 1024  # 5MB
    
    @staticmethod
    def is_mobile_device():
        """Check if the request is from a mobile device"""
        user_agent = request.headers.get('User-Agent', '').lower()
        return any(agent.lower() in user_agent for agent in MobileConfig.MOBILE_USER_AGENTS)
    
    @staticmethod
    def is_tablet_device():
        """Check if the request is from a tablet device"""
        user_agent = request.headers.get('User-Agent', '').lower()
        return 'ipad' in user_agent or 'tablet' in user_agent
    
    @staticmethod
    def get_device_type():
        """Get the device type (mobile, tablet, desktop)"""
        if MobileConfig.is_tablet_device():
            return 'tablet'
        elif MobileConfig.is_mobile_device():
            return 'mobile'
        else:
            return 'desktop'
    
    @staticmethod
    def get_optimized_settings():
        """Get optimized settings based on device type"""
        device_type = MobileConfig.get_device_type()
        
        if device_type == 'mobile':
            return {
                'cache_timeout': MobileConfig.MOBILE_CACHE_TIMEOUT,
                'session_timeout': MobileConfig.MOBILE_SESSION_TIMEOUT,
                'max_upload_size': MobileConfig.MOBILE_MAX_UPLOAD_SIZE,
                'responsive': True,
                'touch_optimized': True
            }
        elif device_type == 'tablet':
            return {
                'cache_timeout': MobileConfig.CACHE_TIMEOUT,
                'session_timeout': MobileConfig.SESSION_TIMEOUT,
                'max_upload_size': MobileConfig.MAX_UPLOAD_SIZE,
                'responsive': True,
                'touch_optimized': True
            }
        else:
            return {
                'cache_timeout': MobileConfig.CACHE_TIMEOUT,
                'session_timeout': MobileConfig.SESSION_TIMEOUT,
                'max_upload_size': MobileConfig.MAX_UPLOAD_SIZE,
                'responsive': True,
                'touch_optimized': False
            }

def mobile_optimized(f):
    """Decorator to optimize views for mobile devices"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Store device type in session
        session['device_type'] = MobileConfig.get_device_type()
        session['is_mobile'] = MobileConfig.is_mobile_device()
        session['is_tablet'] = MobileConfig.is_tablet_device()
        
        # Get optimized settings
        optimized_settings = MobileConfig.get_optimized_settings()
        session['optimized_settings'] = optimized_settings
        
        return f(*args, **kwargs)
    return decorated_function

def internet_access_required(f):
    """Decorator to check internet access requirements"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not MobileConfig.INTERNET_ACCESS:
            from flask import abort
            abort(503, "Internet access is not available")
        
        return f(*args, **kwargs)
    return decorated_function

def rate_limit_check(f):
    """Decorator to check rate limits for internet access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if MobileConfig.RATE_LIMIT_ENABLED:
            # Implement rate limiting logic here
            # This is a basic implementation
            pass
        
        return f(*args, **kwargs)
    return decorated_function

# Mobile-optimized template context
def get_mobile_context():
    """Get mobile-optimized template context"""
    return {
        'is_mobile': MobileConfig.is_mobile_device(),
        'is_tablet': MobileConfig.is_tablet_device(),
        'device_type': MobileConfig.get_device_type(),
        'optimized_settings': MobileConfig.get_optimized_settings(),
        'internet_access': MobileConfig.INTERNET_ACCESS,
        'mobile_optimized': MobileConfig.MOBILE_OPTIMIZED,
        'responsive_design': MobileConfig.RESPONSIVE_DESIGN
    }

# Internet access configuration
class InternetConfig:
    """Internet access configuration settings"""
    
    # Domain settings
    DOMAIN = os.environ.get('DOMAIN', 'localhost:5003')
    SSL_ENABLED = True
    HTTPS_REDIRECT = True
    
    # CDN settings
    CDN_ENABLED = False
    CDN_URL = os.environ.get('CDN_URL', '')
    
    # Performance settings
    COMPRESSION_ENABLED = True
    CACHE_ENABLED = True
    MINIFY_ENABLED = True
    
    # Security settings
    CORS_ENABLED = True
    CORS_ORIGINS = ['*']  # Configure for production
    SECURITY_HEADERS = True
    
    # Monitoring settings
    ANALYTICS_ENABLED = False
    PERFORMANCE_MONITORING = True
    ERROR_TRACKING = True
    
    @staticmethod
    def get_cdn_url(path):
        """Get CDN URL for static files"""
        if InternetConfig.CDN_ENABLED and InternetConfig.CDN_URL:
            return f"{InternetConfig.CDN_URL.rstrip('/')}/{path.lstrip('/')}"
        return path
    
    @staticmethod
    def get_security_headers():
        """Get security headers for internet access"""
        return {
            'X-Frame-Options': 'DENY',
            'X-Content-Type-Options': 'nosniff',
            'X-XSS-Protection': '1; mode=block',
            'Referrer-Policy': 'no-referrer-when-downgrade',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload'
        }

# Network configuration
class NetworkConfig:
    """Network configuration for internet access"""
    
    # Load balancing
    LOAD_BALANCING_ENABLED = False
    BACKEND_SERVERS = ['127.0.0.1:8000']
    
    # Health checks
    HEALTH_CHECK_ENABLED = True
    HEALTH_CHECK_INTERVAL = 30
    HEALTH_CHECK_TIMEOUT = 10
    
    # Failover
    FAILOVER_ENABLED = False
    FAILOVER_TIMEOUT = 60
    
    # Monitoring
    NETWORK_MONITORING = True
    BANDWIDTH_MONITORING = True
    LATENCY_MONITORING = True
    
    @staticmethod
    def get_backend_servers():
        """Get list of backend servers for load balancing"""
        return NetworkConfig.BACKEND_SERVERS
    
    @staticmethod
    def is_healthy():
        """Check if the network is healthy"""
        # Implement health check logic
        return True

# Export configurations
__all__ = [
    'MobileConfig',
    'InternetConfig', 
    'NetworkConfig',
    'mobile_optimized',
    'internet_access_required',
    'rate_limit_check',
    'get_mobile_context'
]

#!/bin/bash

# Alternative start script for Render deployment
# This script provides multiple start options

echo "🚀 Starting Theo's Inventory Management System..."

# Option 1: Use gunicorn config file (if it exists)
if [ -f "gunicorn.conf.py" ]; then
    echo "✅ Using gunicorn configuration file"
    exec gunicorn --config gunicorn.conf.py wsgi:app
fi

# Option 2: Use simple gunicorn command
echo "✅ Using simple gunicorn command"
exec gunicorn --bind 0.0.0.0:$PORT --workers 2 --timeout 30 wsgi:app

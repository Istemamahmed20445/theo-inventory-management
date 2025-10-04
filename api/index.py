# Vercel serverless function entry point
from wsgi import app

# This is the entry point for Vercel
def handler(request):
    return app(request.environ, lambda *args, **kwargs: None)

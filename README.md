# 🏪 Theo's Inventory Management System

A modern, feature-rich inventory management system built with Flask and Firebase, designed for clothing and retail businesses.

## ✨ Features

- 📦 **Product Management** - Add, edit, and organize products with images
- 🏷️ **Category & Variant Management** - Organize by categories, colors, and sizes
- 👥 **Customer Management** - Track customer information and purchase history
- 💰 **Sales Tracking** - Record and monitor sales transactions
- 📊 **Dashboard Analytics** - Real-time insights and reporting
- 📱 **Mobile Responsive** - Works perfectly on all devices
- 🔍 **Barcode Scanning** - Quick product lookup and management
- 📈 **Excel Import/Export** - Bulk operations and data management
- 🔥 **Firebase Integration** - Cloud storage and real-time database
- 🎨 **Modern UI** - Clean, intuitive interface

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Firebase project setup
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/theo-inventory-management.git
   cd theo-inventory-management
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Setup environment variables**
   ```bash
   cp env.template .env
   # Edit .env with your Firebase credentials
   ```

5. **Upload Firebase credentials**
   - Place your `firebase-service-account.json` in the project root
   - Or configure environment variables (see config.py)

6. **Run the application**
   ```bash
   python app.py
   ```

7. **Access the application**
   - Open http://localhost:5000
   - Default login: `admin` / `admin123`

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your-super-secret-key-here
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
```

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Firestore Database
3. Enable Storage
4. Generate a service account key
5. Download the JSON file and place it in your project root

## 🌐 Deployment

### Railway Deployment

This app is configured for easy deployment on Railway:

1. **Push to GitHub** (if not already done)
   ```bash
   python setup_github.py
   ```

2. **Deploy on Railway**
   - Go to https://railway.app/
   - Sign up with GitHub
   - Create new project from GitHub repo
   - Select your repository
   - Configure environment variables
   - Deploy!

3. **Custom Domain** (Optional)
   - Set up custom domain in Railway dashboard
   - Example: `theoclothinginventory.railway.app`

### Other Deployment Options

- **Heroku**: Use the included Procfile
- **DigitalOcean**: Use the Dockerfile
- **AWS/GCP**: Use the provided deployment scripts

## 📱 Usage

### Default Login
- Username: `admin`
- Password: `admin123`

### Key Features

1. **Products**
   - Add products with images, descriptions, and variants
   - Organize by categories, colors, and sizes
   - Barcode scanning for quick lookup

2. **Sales**
   - Record sales transactions
   - Track customer purchases
   - Generate sales reports

3. **Inventory**
   - Monitor stock levels
   - Set low stock alerts
   - Track product movements

4. **Analytics**
   - Sales dashboard
   - Product performance metrics
   - Customer insights

## 🛠️ Development

### Project Structure

```
├── app.py                 # Main Flask application
├── config.py             # Configuration settings
├── wsgi.py               # WSGI entry point for production
├── requirements.txt      # Python dependencies
├── Procfile             # Heroku/Railway deployment config
├── railway.json         # Railway deployment config
├── static/              # Static assets (CSS, JS, images)
├── templates/           # HTML templates
└── logs/                # Application logs
```

### Adding New Features

1. Create new routes in `app.py`
2. Add corresponding templates in `templates/`
3. Update static assets in `static/`
4. Test locally before deploying

## 🔒 Security

- Change default admin credentials
- Use strong SECRET_KEY in production
- Enable HTTPS in production
- Regularly update dependencies
- Secure Firebase rules

## 📞 Support

For support or questions:
- Create an issue on GitHub
- Check the documentation
- Review the deployment guides

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flask for the web framework
- Firebase for backend services
- Bootstrap for UI components
- All contributors and testers

---

**Made with ❤️ for modern inventory management**
// Main JavaScript file for Garment Inventory Management System

// Global variables
let currentUser = null;
let products = [];
let users = [];

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
    loadDashboardData();
});

// Initialize application
function initializeApp() {
    // Check if user is logged in
    if (typeof session !== 'undefined' && session.user_id) {
        currentUser = {
            id: session.user_id,
            username: session.username,
            role: session.role,
            permissions: session.permissions
        };
    }
    
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });
}

// Setup event listeners
function setupEventListeners() {
    // Search functionality
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', handleSearch);
    }
    
    // Category filter
    const categoryFilter = document.getElementById('categoryFilter');
    if (categoryFilter) {
        categoryFilter.addEventListener('change', handleCategoryFilter);
    }
    
    // Form validation
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', handleFormSubmit);
    });
    
    // Image preview
    const imageInputs = document.querySelectorAll('input[type="file"][accept*="image"]');
    imageInputs.forEach(input => {
        input.addEventListener('change', handleImagePreview);
    });
    
    // Auto-save functionality
    const autoSaveInputs = document.querySelectorAll('[data-auto-save]');
    autoSaveInputs.forEach(input => {
        input.addEventListener('blur', handleAutoSave);
    });
}

// Handle search functionality
function handleSearch(event) {
    const searchTerm = event.target.value.toLowerCase();
    const productCards = document.querySelectorAll('.product-card');
    
    productCards.forEach(card => {
        const productName = card.dataset.name || '';
        const productDescription = card.dataset.description || '';
        
        if (productName.includes(searchTerm) || productDescription.includes(searchTerm)) {
            card.style.display = 'block';
            card.classList.add('fade-in');
        } else {
            card.style.display = 'none';
        }
    });
}

// Handle category filter
function handleCategoryFilter(event) {
    const selectedCategory = event.target.value;
    const productCards = document.querySelectorAll('.product-card');
    
    productCards.forEach(card => {
        const productCategory = card.dataset.category || '';
        
        if (selectedCategory === '' || productCategory === selectedCategory) {
            card.style.display = 'block';
            card.classList.add('fade-in');
        } else {
            card.style.display = 'none';
        }
    });
}

// Handle form submission
function handleFormSubmit(event) {
    const form = event.target;
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    // Clear previous validation
    requiredFields.forEach(field => {
        field.classList.remove('is-invalid');
    });
    
    // Validate required fields
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            field.classList.add('is-invalid');
            isValid = false;
        }
    });
    
    // Validate email fields
    const emailFields = form.querySelectorAll('input[type="email"]');
    emailFields.forEach(field => {
        if (field.value && !isValidEmail(field.value)) {
            field.classList.add('is-invalid');
            isValid = false;
        }
    });
    
    // Validate number fields
    const numberFields = form.querySelectorAll('input[type="number"]');
    numberFields.forEach(field => {
        if (field.value && (isNaN(field.value) || field.value < 0)) {
            field.classList.add('is-invalid');
            isValid = false;
        }
    });
    
    if (!isValid) {
        event.preventDefault();
        showAlert('Please fill in all required fields correctly.', 'danger');
    }
}

// Handle image preview
function handleImagePreview(event) {
    const file = event.target.files[0];
    const preview = document.getElementById('imagePreview');
    
    if (file) {
        // Validate file type
        if (!file.type.startsWith('image/')) {
            showAlert('Please select a valid image file.', 'danger');
            event.target.value = '';
            return;
        }
        
        // Validate file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
            showAlert('Image size too large. Please select an image smaller than 5MB.', 'danger');
            event.target.value = '';
            return;
        }
        
        const reader = new FileReader();
        reader.onload = function(e) {
            if (preview) {
                preview.innerHTML = '<img src="' + e.target.result + '" class="img-fluid rounded" alt="Preview">';
            }
        };
        reader.readAsDataURL(file);
    } else {
        if (preview) {
            preview.innerHTML = '<i class="fas fa-image fa-3x text-muted"></i><p class="text-muted mt-2">No image selected</p>';
        }
    }
}

// Handle auto-save
function handleAutoSave(event) {
    const field = event.target;
    const data = {
        [field.name]: field.value
    };
    
    // Send auto-save request
    fetch('/api/auto-save', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showAlert('Changes saved automatically.', 'success', 2000);
        }
    })
    .catch(error => {
        console.error('Auto-save error:', error);
    });
}

// Load dashboard data
function loadDashboardData() {
    // This would typically load data via AJAX
    // For now, we'll just initialize the dashboard
    updateDashboardStats();
}

// Update dashboard statistics
function updateDashboardStats() {
    // This would typically fetch real data from the server
    // For now, we'll just animate the numbers
    const statElements = document.querySelectorAll('.dashboard-card h4');
    statElements.forEach(element => {
        animateNumber(element);
    });
}

// Animate number counting
function animateNumber(element) {
    const target = parseInt(element.textContent) || 0;
    const duration = 1000;
    const step = target / (duration / 16);
    let current = 0;
    
    const timer = setInterval(() => {
        current += step;
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }
        element.textContent = Math.floor(current);
    }, 16);
}

// Show alert message
function showAlert(message, type = 'info', duration = 5000) {
    const alertContainer = document.querySelector('.container-fluid');
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    alertContainer.insertBefore(alertDiv, alertContainer.firstChild);
    
    // Auto-dismiss after duration
    if (duration > 0) {
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, duration);
    }
}

// Validate email format
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

// Format date
function formatDate(date) {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(new Date(date));
}

// Generate barcode
function generateBarcode(text) {
    // This would typically use a barcode library
    // For now, we'll just return a placeholder
    return `BARCODE_${text.toUpperCase()}`;
}

// Print functionality
function printPage() {
    window.print();
}

// Export to PDF
function exportToPDF() {
    // This would typically use a PDF library
    showAlert('PDF export functionality would be implemented here.', 'info');
}

// Check user permissions
function hasPermission(permission) {
    if (!currentUser || !currentUser.permissions) {
        return false;
    }
    return currentUser.permissions.includes(permission);
}

// Show/hide elements based on permissions
function updateUIForPermissions() {
    const elements = document.querySelectorAll('[data-permission]');
    elements.forEach(element => {
        const permission = element.dataset.permission;
        if (!hasPermission(permission)) {
            element.style.display = 'none';
        }
    });
}

// Handle keyboard shortcuts
document.addEventListener('keydown', function(event) {
    // Ctrl/Cmd + S to save
    if ((event.ctrlKey || event.metaKey) && event.key === 's') {
        event.preventDefault();
        const form = document.querySelector('form');
        if (form) {
            form.submit();
        }
    }
    
    // Ctrl/Cmd + N to add new product
    if ((event.ctrlKey || event.metaKey) && event.key === 'n') {
        event.preventDefault();
        const addButton = document.querySelector('a[href*="add_product"]');
        if (addButton) {
            addButton.click();
        }
    }
    
    // Escape to close modals
    if (event.key === 'Escape') {
        const modals = document.querySelectorAll('.modal.show');
        modals.forEach(modal => {
            const modalInstance = bootstrap.Modal.getInstance(modal);
            if (modalInstance) {
                modalInstance.hide();
            }
        });
    }
});

// Handle window resize
window.addEventListener('resize', function() {
    // Update responsive elements
    const cards = document.querySelectorAll('.product-card');
    cards.forEach(card => {
        if (window.innerWidth < 768) {
            card.classList.add('mobile-view');
        } else {
            card.classList.remove('mobile-view');
        }
    });
});

// Handle online/offline status
window.addEventListener('online', function() {
    showAlert('Connection restored. You are now online.', 'success');
});

window.addEventListener('offline', function() {
    showAlert('Connection lost. You are now offline. Some features may not work.', 'warning');
});

// Service Worker registration (for PWA functionality)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        navigator.serviceWorker.register('/sw.js')
            .then(function(registration) {
                console.log('ServiceWorker registration successful');
            })
            .catch(function(err) {
                console.log('ServiceWorker registration failed');
            });
    });
}

// Export functions for global use
window.InventoryApp = {
    showAlert,
    formatCurrency,
    formatDate,
    generateBarcode,
    printPage,
    exportToPDF,
    hasPermission,
    updateUIForPermissions
};

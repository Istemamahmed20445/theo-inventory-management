#!/usr/bin/env python3
"""
Corporate User Management Script
Creates and manages corporate users for the inventory system
"""

import os
import sys
import json
from datetime import datetime
from firebase_admin import credentials, firestore
import firebase_admin

# Initialize Firebase
def init_firebase():
    if not os.path.exists('firebase-service-account.json'):
        print("Error: Firebase service account file not found!")
        print("Please download your Firebase service account JSON file and save it as 'firebase-service-account.json'")
        sys.exit(1)
    
    cred = credentials.Certificate("firebase-service-account.json")
    firebase_admin.initialize_app(cred)
    return firestore.client()

# Corporate user roles and permissions
CORPORATE_ROLES = {
    'admin': {
        'name': 'Administrator',
        'permissions': [
            'view_products', 'add_products', 'edit_products', 'delete_products',
            'view_sales', 'add_sales', 'edit_sales', 'delete_sales',
            'view_production', 'add_production', 'edit_production', 'delete_production',
            'view_customers', 'add_customers', 'edit_customers', 'delete_customers',
            'view_categories', 'add_categories', 'edit_categories', 'delete_categories',
            'view_reports', 'excel_import', 'excel_export', 'user_management',
            'system_settings', 'backup_management'
        ]
    },
    'manager': {
        'name': 'Manager',
        'permissions': [
            'view_products', 'add_products', 'edit_products',
            'view_sales', 'add_sales', 'edit_sales',
            'view_production', 'add_production', 'edit_production',
            'view_customers', 'add_customers', 'edit_customers',
            'view_categories', 'add_categories', 'edit_categories',
            'view_reports', 'excel_import', 'excel_export'
        ]
    },
    'staff': {
        'name': 'Staff',
        'permissions': [
            'view_products', 'add_products', 'edit_products',
            'view_sales', 'add_sales',
            'view_production', 'add_production',
            'view_customers', 'add_customers',
            'view_categories', 'add_categories',
            'view_reports'
        ]
    },
    'viewer': {
        'name': 'Viewer',
        'permissions': [
            'view_products', 'view_sales', 'view_production',
            'view_customers', 'view_categories', 'view_reports'
        ]
    }
}

def create_corporate_user(db, username, password, role, email, full_name, department):
    """Create a new corporate user"""
    try:
        # Check if user already exists
        users_ref = db.collection('users')
        existing_user = users_ref.where('username', '==', username).get()
        
        if existing_user:
            print(f"Error: User '{username}' already exists!")
            return False
        
        # Get role permissions
        if role not in CORPORATE_ROLES:
            print(f"Error: Invalid role '{role}'. Available roles: {list(CORPORATE_ROLES.keys())}")
            return False
        
        role_data = CORPORATE_ROLES[role]
        
        # Create user data
        user_data = {
            'username': username,
            'password': password,
            'role': role,
            'role_name': role_data['name'],
            'permissions': role_data['permissions'],
            'email': email,
            'full_name': full_name,
            'department': department,
            'created_at': datetime.now(),
            'created_by': 'corporate_setup',
            'active': True,
            'last_login': None,
            'login_count': 0
        }
        
        # Add user to database
        db.collection('users').add(user_data)
        
        print(f"✅ Corporate user '{username}' created successfully!")
        print(f"   Role: {role_data['name']}")
        print(f"   Department: {department}")
        print(f"   Permissions: {len(role_data['permissions'])} permissions")
        
        return True
        
    except Exception as e:
        print(f"Error creating user: {str(e)}")
        return False

def list_corporate_users(db):
    """List all corporate users"""
    try:
        users_ref = db.collection('users')
        users = users_ref.get()
        
        if not users:
            print("No users found in the system.")
            return
        
        print("\n📋 Corporate Users:")
        print("=" * 80)
        print(f"{'Username':<15} {'Full Name':<20} {'Role':<10} {'Department':<15} {'Status':<8}")
        print("-" * 80)
        
        for user in users:
            user_data = user.to_dict()
            status = "Active" if user_data.get('active', True) else "Inactive"
            print(f"{user_data.get('username', 'N/A'):<15} "
                  f"{user_data.get('full_name', 'N/A'):<20} "
                  f"{user_data.get('role_name', 'N/A'):<10} "
                  f"{user_data.get('department', 'N/A'):<15} "
                  f"{status:<8}")
        
        print("=" * 80)
        
    except Exception as e:
        print(f"Error listing users: {str(e)}")

def update_user_role(db, username, new_role):
    """Update user role"""
    try:
        if new_role not in CORPORATE_ROLES:
            print(f"Error: Invalid role '{new_role}'. Available roles: {list(CORPORATE_ROLES.keys())}")
            return False
        
        # Find user
        users_ref = db.collection('users')
        user_query = users_ref.where('username', '==', username).get()
        
        if not user_query:
            print(f"Error: User '{username}' not found!")
            return False
        
        user_doc = user_query[0]
        role_data = CORPORATE_ROLES[new_role]
        
        # Update user
        user_doc.reference.update({
            'role': new_role,
            'role_name': role_data['name'],
            'permissions': role_data['permissions'],
            'updated_at': datetime.now(),
            'updated_by': 'corporate_setup'
        })
        
        print(f"✅ User '{username}' role updated to {role_data['name']}")
        return True
        
    except Exception as e:
        print(f"Error updating user role: {str(e)}")
        return False

def deactivate_user(db, username):
    """Deactivate a user"""
    try:
        # Find user
        users_ref = db.collection('users')
        user_query = users_ref.where('username', '==', username).get()
        
        if not user_query:
            print(f"Error: User '{username}' not found!")
            return False
        
        user_doc = user_query[0]
        
        # Deactivate user
        user_doc.reference.update({
            'active': False,
            'deactivated_at': datetime.now(),
            'deactivated_by': 'corporate_setup'
        })
        
        print(f"✅ User '{username}' deactivated successfully")
        return True
        
    except Exception as e:
        print(f"Error deactivating user: {str(e)}")
        return False

def create_default_corporate_users(db):
    """Create default corporate users"""
    print("Creating default corporate users...")
    
    default_users = [
        {
            'username': 'admin',
            'password': 'admin123',
            'role': 'admin',
            'email': 'admin@yourcompany.com',
            'full_name': 'System Administrator',
            'department': 'IT'
        },
        {
            'username': 'manager',
            'password': 'manager123',
            'role': 'manager',
            'email': 'manager@yourcompany.com',
            'full_name': 'Inventory Manager',
            'department': 'Operations'
        },
        {
            'username': 'staff',
            'password': 'staff123',
            'role': 'staff',
            'email': 'staff@yourcompany.com',
            'full_name': 'Inventory Staff',
            'department': 'Operations'
        }
    ]
    
    for user_data in default_users:
        create_corporate_user(db, **user_data)

def main():
    print("🏢 Corporate User Management System")
    print("=" * 50)
    
    # Initialize Firebase
    db = init_firebase()
    
    while True:
        print("\n📋 Corporate User Management Options:")
        print("1. Create new user")
        print("2. List all users")
        print("3. Update user role")
        print("4. Deactivate user")
        print("5. Create default users")
        print("6. Exit")
        
        choice = input("\nEnter your choice (1-6): ").strip()
        
        if choice == '1':
            print("\n👤 Create New Corporate User")
            username = input("Username: ").strip()
            password = input("Password: ").strip()
            role = input(f"Role ({'/'.join(CORPORATE_ROLES.keys())}): ").strip().lower()
            email = input("Email: ").strip()
            full_name = input("Full Name: ").strip()
            department = input("Department: ").strip()
            
            create_corporate_user(db, username, password, role, email, full_name, department)
            
        elif choice == '2':
            list_corporate_users(db)
            
        elif choice == '3':
            print("\n🔄 Update User Role")
            username = input("Username: ").strip()
            new_role = input(f"New Role ({'/'.join(CORPORATE_ROLES.keys())}): ").strip().lower()
            update_user_role(db, username, new_role)
            
        elif choice == '4':
            print("\n🚫 Deactivate User")
            username = input("Username: ").strip()
            confirm = input(f"Are you sure you want to deactivate '{username}'? (y/n): ").strip().lower()
            if confirm == 'y':
                deactivate_user(db, username)
            
        elif choice == '5':
            confirm = input("Create default corporate users? (y/n): ").strip().lower()
            if confirm == 'y':
                create_default_corporate_users(db)
            
        elif choice == '6':
            print("👋 Goodbye!")
            break
            
        else:
            print("❌ Invalid choice. Please try again.")

if __name__ == "__main__":
    main()

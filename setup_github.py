#!/usr/bin/env python3
"""
GitHub Repository Setup Script for Inventory Management System
This script automates the process of adding your project to GitHub
"""

import os
import subprocess
import sys
from pathlib import Path

def run_command(command, description):
    """Run a shell command and handle errors"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Error during {description}: {e.stderr}")
        return None

def check_git_installed():
    """Check if git is installed"""
    result = run_command("git --version", "Checking git installation")
    return result is not None

def check_github_cli():
    """Check if GitHub CLI is installed"""
    result = run_command("gh --version", "Checking GitHub CLI installation")
    return result is not None

def initialize_git_repo():
    """Initialize git repository"""
    if os.path.exists('.git'):
        print("📁 Git repository already initialized")
        return True
    
    return run_command("git init", "Initializing git repository") is not None

def add_all_files():
    """Add all files to git"""
    return run_command("git add .", "Adding all files to git") is not None

def create_initial_commit():
    """Create initial commit"""
    return run_command('git commit -m "Initial commit: Inventory Management System"', "Creating initial commit") is not None

def setup_git_config():
    """Setup git user configuration if not already set"""
    # Check if git config is already set
    try:
        subprocess.run("git config user.name", shell=True, check=True, capture_output=True)
        subprocess.run("git config user.email", shell=True, check=True, capture_output=True)
        print("✅ Git user configuration already set")
        return True
    except subprocess.CalledProcessError:
        print("⚠️  Git user configuration not set. Please run:")
        print("   git config --global user.name 'Your Name'")
        print("   git config --global user.email 'your.email@example.com'")
        return False

def create_github_repo():
    """Create GitHub repository using GitHub CLI"""
    if not check_github_cli():
        print("❌ GitHub CLI not installed. Please install it from: https://cli.github.com/")
        return None
    
    # Check if user is logged in to GitHub CLI
    try:
        subprocess.run("gh auth status", shell=True, check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print("❌ Not logged in to GitHub CLI. Please run: gh auth login")
        return None
    
    repo_name = "theo-inventory-management"
    description = "Modern Inventory Management System with Firebase integration"
    
    command = f'gh repo create {repo_name} --public --description "{description}" --source=. --remote=origin --push'
    
    print(f"🚀 Creating GitHub repository: {repo_name}")
    result = run_command(command, f"Creating GitHub repository '{repo_name}'")
    
    if result:
        repo_url = f"https://github.com/$(gh api user --jq .login)/{repo_name}"
        print(f"✅ Repository created successfully: {repo_url}")
        return repo_url
    
    return None

def main():
    """Main setup function"""
    print("🚀 GitHub Repository Setup for Inventory Management System")
    print("=" * 60)
    
    # Change to project directory
    project_dir = Path(__file__).parent
    os.chdir(project_dir)
    print(f"📁 Working in: {project_dir}")
    
    # Check prerequisites
    if not check_git_installed():
        print("❌ Git is not installed. Please install git first.")
        sys.exit(1)
    
    # Setup git configuration
    if not setup_git_config():
        print("⚠️  Please configure git user settings and run this script again.")
        sys.exit(1)
    
    # Initialize git repository
    if not initialize_git_repo():
        print("❌ Failed to initialize git repository")
        sys.exit(1)
    
    # Add all files
    if not add_all_files():
        print("❌ Failed to add files to git")
        sys.exit(1)
    
    # Create initial commit
    if not create_initial_commit():
        print("❌ Failed to create initial commit")
        sys.exit(1)
    
    # Create GitHub repository
    repo_url = create_github_repo()
    
    if repo_url:
        print("\n🎉 SUCCESS! Your inventory management system is now on GitHub!")
        print(f"📍 Repository URL: {repo_url}")
        print("\n📋 Next Steps:")
        print("1. Go to Railway.app and sign up")
        print("2. Create new project from GitHub repo")
        print("3. Select your repository")
        print("4. Configure environment variables")
        print("5. Deploy!")
        print(f"\n🔗 Railway will automatically deploy from: {repo_url}")
    else:
        print("\n⚠️  GitHub repository creation failed.")
        print("You can manually create a repository at: https://github.com/new")
        print("Then run: git remote add origin <your-repo-url>")
        print("Then run: git push -u origin main")

if __name__ == "__main__":
    main()

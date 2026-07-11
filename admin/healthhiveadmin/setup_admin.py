#!/usr/bin/env python3
"""
HealthHive Admin Panel Setup Script
"""

import os
import sys
import subprocess
import platform

def print_banner():
    print("=" * 60)
    print("🏥 HealthHive Admin Panel Setup")
    print("=" * 60)
    print()

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"📋 {description}...")
    try:
        if platform.system() == "Windows":
            result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        else:
            result = subprocess.run(command.split(), check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {description} failed")
        print(f"   Command: {command}")
        print(f"   Error: {e.stderr if e.stderr else 'Unknown error'}")
        return False
    except FileNotFoundError:
        print(f"❌ Error: Command not found - {command.split()[0]}")
        return False

def check_python():
    """Check if Python is installed"""
    try:
        result = subprocess.run([sys.executable, "--version"], capture_output=True, text=True)
        version = result.stdout.strip()
        print(f"✅ Python found: {version}")
        return True
    except:
        print("❌ Python not found. Please install Python 3.8+ first.")
        print("   Download from: https://www.python.org/downloads/")
        return False

def main():
    print_banner()
    
    # Check Python
    if not check_python():
        return False
    
    print("\n🔧 Setting up HealthHive Admin Panel...\n")
    
    # Install requirements
    if not run_command(f"{sys.executable} -m pip install -r requirements.txt", "Installing Python packages"):
        print("\n💡 Try running: pip install Django==4.2.7 Pillow==10.0.1")
        return False
    
    # Make migrations
    if not run_command(f"{sys.executable} manage.py makemigrations", "Creating database migrations"):
        return False
    
    # Run migrations
    if not run_command(f"{sys.executable} manage.py migrate", "Setting up database"):
        return False
    
    # Create superuser
    print("\n👤 Creating admin user...")
    print("Please follow the prompts to create an admin account:")
    try:
        subprocess.run([sys.executable, "manage.py", "createsuperuser"], check=True)
        print("✅ Admin user created successfully")
    except subprocess.CalledProcessError:
        print("⚠️  Admin user creation skipped or failed")
    except KeyboardInterrupt:
        print("\n⚠️  Admin user creation cancelled")
    
    # Success message
    print("\n" + "=" * 60)
    print("🎉 HealthHive Admin Panel Setup Complete!")
    print("=" * 60)
    print("\n📋 Next Steps:")
    print("1. Start the server:")
    print(f"   {sys.executable} manage.py runserver")
    print("\n2. Open your browser and visit:")
    print("   🌐 Admin Panel: http://127.0.0.1:8000/")
    print("   🔧 Django Admin: http://127.0.0.1:8000/admin/")
    print("\n3. Login with the admin credentials you just created")
    print("\n🎨 Features:")
    print("   • Beautiful pastel color design")
    print("   • User management system")
    print("   • Medicine & appointment reminders")
    print("   • Responsive dashboard")
    print("   • Secure authentication")
    
    return True

if __name__ == "__main__":
    try:
        success = main()
        if not success:
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Setup cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
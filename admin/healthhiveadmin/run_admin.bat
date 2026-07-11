@echo off
echo ========================================
echo   HealthHive Admin Panel Setup
echo ========================================
echo.

echo Checking Python installation...
python --version
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python from https://python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo.
echo Installing required packages...
python -m pip install --upgrade pip
python -m pip install Django==4.2.7 Pillow==10.0.1

echo.
echo Setting up database...
python manage.py makemigrations
python manage.py migrate

echo.
echo Creating admin user...
echo Please create an admin account when prompted:
python manage.py createsuperuser

echo.
echo ========================================
echo   Setup Complete! Starting Server...
echo ========================================
echo.
echo Your admin panel will be available at:
echo   http://127.0.0.1:8000/
echo.
echo Press Ctrl+C to stop the server
echo.
python manage.py runserver

pause
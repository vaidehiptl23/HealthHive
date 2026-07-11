#!/bin/bash

# HealthHive API Test Script
# This script tests the basic functionality of the API

echo "🧪 HealthHive API Test Script"
echo "=============================="

# Base URL
BASE_URL="http://localhost:5000/api"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to make API request
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    local curl_cmd="curl -s -X $method '$BASE_URL$endpoint'"
    
    if [ ! -z "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    if [ ! -z "$token" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $token'"
    fi
    
    eval $curl_cmd
}

# Test 1: Check if server is running
echo ""
echo "1. Testing server status..."
response=$(curl -s http://localhost:5000)
if [[ $response == *"HealthHive"* ]]; then
    print_success "Server is running"
    echo "   Response: $response"
else
    print_error "Server is not running"
    echo "   Please start the server with: npm start"
    exit 1
fi

# Test 2: Register a new user
echo ""
echo "2. Testing user registration..."
register_data='{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123",
  "phone": "1234567890"
}'

register_response=$(make_request "POST" "/auth/register" "$register_data")
if [[ $register_response == *"success"*true* ]]; then
    print_success "User registration successful"
    # Extract token for later tests
    TOKEN=$(echo $register_response | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    USER_ID=$(echo $register_response | grep -o '"id":[0-9]*' | cut -d':' -f2)
else
    print_error "User registration failed"
    echo "   Response: $register_response"
    # Try login instead if user already exists
    echo "   Trying login instead..."
    login_data='{
      "email": "test@example.com",
      "password": "password123"
    }'
    login_response=$(make_request "POST" "/auth/login" "$login_data")
    if [[ $login_response == *"success"*true* ]]; then
        print_success "Login successful"
        TOKEN=$(echo $login_response | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        USER_ID=$(echo $login_response | grep -o '"id":[0-9]*' | cut -d':' -f2)
    else
        print_error "Login also failed"
        echo "   Response: $login_response"
        exit 1
    fi
fi

# Test 3: Create a reminder
echo ""
echo "3. Testing reminder creation..."
reminder_data='{
  "title": "Test Reminder",
  "description": "This is a test reminder",
  "dateTime": "'$(date -d "+1 hour" '+%Y-%m-%d %H:%M:%S')'"
}'

reminder_response=$(make_request "POST" "/reminders" "$reminder_data" "$TOKEN")
if [[ $reminder_response == *"success"*true* ]]; then
    print_success "Reminder created successfully"
    REMINDER_ID=$(echo $reminder_response | grep -o '"id":[0-9]*' | cut -d':' -f2)
else
    print_error "Reminder creation failed"
    echo "   Response: $reminder_response"
fi

# Test 4: Get all reminders
echo ""
echo "4. Testing get all reminders..."
reminders_response=$(make_request "GET" "/reminders" "" "$TOKEN")
if [[ $reminders_response == *"success"*true* ]]; then
    print_success "Got reminders successfully"
    reminder_count=$(echo $reminders_response | grep -o '"id":[0-9]*' | wc -l)
    echo "   Found $reminder_count reminder(s)"
else
    print_error "Failed to get reminders"
    echo "   Response: $reminders_response"
fi

# Test 5: Create a health record
echo ""
echo "5. Testing health record creation..."
health_data='{
  "type": "Blood Pressure",
  "value": "120/80",
  "date": "'$(date '+%Y-%m-%d')'",
  "notes": "Test reading"
}'

health_response=$(make_request "POST" "/health" "$health_data" "$TOKEN")
if [[ $health_response == *"success"*true* ]]; then
    print_success "Health record created successfully"
else
    print_error "Health record creation failed"
    echo "   Response: $health_response"
fi

# Test 6: Get user profile
echo ""
echo "6. Testing get user profile..."
profile_response=$(make_request "GET" "/profile" "" "$TOKEN")
if [[ $profile_response == *"success"*true* ]]; then
    print_success "Got profile successfully"
    USER_NAME=$(echo $profile_response | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    echo "   User: $USER_NAME"
else
    print_error "Failed to get profile"
    echo "   Response: $profile_response"
fi

# Test 7: Add a family member
echo ""
echo "7. Testing add family member..."
family_data='{
  "name": "Test Family Member",
  "relation": "Spouse",
  "phone": "0987654321"
}'

family_response=$(make_request "POST" "/family" "$family_data" "$TOKEN")
if [[ $family_response == *"success"*true* ]]; then
    print_success "Family member added successfully"
else
    print_error "Failed to add family member"
    echo "   Response: $family_response"
fi

# Summary
echo ""
echo "=============================="
echo "🧪 Test Summary"
echo "=============================="
echo "Server Status: $(if [[ $response == *"HealthHive"* ]]; then echo "✅ Running"; else echo "❌ Not Running"; fi)"
echo "Authentication: $(if [ ! -z "$TOKEN" ]; then echo "✅ Success (Token obtained)"; else echo "❌ Failed"; fi)"
echo "Reminder Creation: $(if [[ $reminder_response == *"success"*true* ]]; then echo "✅ Success"; else echo "❌ Failed"; fi)"
echo "Health Record: $(if [[ $health_response == *"success"*true* ]]; then echo "✅ Success"; else echo "❌ Failed"; fi)"
echo "Profile Access: $(if [[ $profile_response == *"success"*true* ]]; then echo "✅ Success"; else echo "❌ Failed"; fi)"
echo "Family Member: $(if [[ $family_response == *"success"*true* ]]; then echo "✅ Success"; else echo "❌ Failed"; fi)"
echo ""
echo "📝 Next Steps:"
echo "1. Update Flutter app API URL to: http://localhost:5000/api"
echo "2. Test with Flutter app"
echo "3. Check MySQL database for created data"
echo ""
echo "🎉 API is ready to use!"
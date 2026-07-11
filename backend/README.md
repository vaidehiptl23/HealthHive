# HealthHive Backend API

A complete Node.js + Express + MySQL backend for the HealthHive health management application.

## Features

- ✅ User authentication (register/login with JWT)
- ✅ Reminders management
- ✅ Health records tracking
- ✅ Document upload/download
- ✅ Family members management
- ✅ User profile management
- ✅ MySQL database with proper relationships
- ✅ File upload support (images & PDFs)
- ✅ CORS enabled for Flutter app
- ✅ Input validation
- ✅ Error handling

## Prerequisites

1. **Node.js** (v14 or higher)
2. **MySQL** (v5.7 or higher)
3. **npm** or **yarn**

## Installation

### 1. Clone and navigate to backend directory
```bash
cd backend
```

### 2. Install dependencies
```bash
npm install
```

### 3. Set up MySQL Database

#### Option A: Using MySQL Command Line
```sql
-- Login to MySQL
mysql -u root -p

-- Create database
CREATE DATABASE healthhive;

-- Use the database
USE healthhive;
```

#### Option B: Using MySQL Workbench
1. Open MySQL Workbench
2. Connect to your MySQL server
3. Create a new schema named `healthhive`
4. Run the SQL script in `database.sql` (if available)

### 4. Configure Environment Variables

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` file with your MySQL credentials:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=healthhive
DB_PORT=3306
```

### 5. Start the Server

#### Development mode (with auto-restart):
```bash
npm run dev
```

#### Production mode:
```bash
npm start
```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile

### Reminders
- `GET /api/reminders` - Get all reminders
- `GET /api/reminders/upcoming` - Get upcoming reminders
- `GET /api/reminders/:id` - Get single reminder
- `POST /api/reminders` - Create new reminder
- `PUT /api/reminders/:id` - Update reminder
- `DELETE /api/reminders/:id` - Delete reminder

### Health Records
- `GET /api/health` - Get all health records
- `GET /api/health/:id` - Get single health record
- `GET /api/health/type/:type` - Get records by type
- `POST /api/health` - Create new health record
- `PUT /api/health/:id` - Update health record
- `DELETE /api/health/:id` - Delete health record

### Documents
- `GET /api/documents` - Get all documents
- `GET /api/documents/:id` - Get single document
- `GET /api/documents/download/:id` - Download document
- `POST /api/documents` - Upload new document
- `DELETE /api/documents/:id` - Delete document

### Family Members
- `GET /api/family` - Get all family members
- `GET /api/family/:id` - Get single family member
- `POST /api/family` - Add new family member
- `PUT /api/family/:id` - Update family member
- `DELETE /api/family/:id` - Delete family member

### Profile
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update profile
- `PUT /api/profile/change-password` - Change password
- `DELETE /api/profile` - Delete account

## Database Schema

The backend automatically creates these tables on startup:

1. **users** - User accounts
2. **reminders** - Medication/appointment reminders
3. **health_records** - Health measurements
4. **documents** - Medical documents
5. **family_members** - Family member information

## File Upload

- Supported file types: JPEG, PNG, PDF
- Maximum file size: 5MB
- Files are stored in `backend/uploads/` directory
- File paths are stored in database

## Testing the API

### 1. Test server is running:
```bash
curl http://localhost:5000
```
Response: `{"message":"HealthHive API Running with MySQL"}`

### 2. Register a new user:
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "phone": "1234567890"
  }'
```

### 3. Login:
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

## Connecting Flutter App

Update the API base URL in your Flutter app:

```dart
// In lib/services/api_service.dart
static const String baseUrl = 'http://localhost:5000/api';
// For mobile testing: 'http://YOUR_PC_IP:5000/api'
```

## Troubleshooting

### 1. MySQL Connection Error
- Check if MySQL service is running
- Verify credentials in `.env` file
- Ensure database `healthhive` exists

### 2. Port Already in Use
- Change `PORT` in `.env` file
- Kill process using port 5000: `kill -9 $(lsof -t -i:5000)`

### 3. File Upload Issues
- Ensure `uploads/` directory exists
- Check file size (max 5MB)
- Verify file type (JPEG, PNG, PDF only)

### 4. CORS Errors
- Ensure Flutter app URL is allowed
- Check `app.use(cors())` in server.js

## Development

### Project Structure
```
backend/
├── config/          # Database configuration
├── middleware/      # Authentication & upload middleware
├── routes/         # API route handlers
├── uploads/        # Uploaded files (auto-created)
├── .env           # Environment variables
├── .env.example   # Environment template
├── package.json   # Dependencies
└── server.js      # Main server file
```

### Adding New Features
1. Create new route file in `routes/`
2. Add route to `server.js`
3. Update database schema if needed
4. Test with Postman or curl

## License

MIT
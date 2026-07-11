const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Load environment variables
dotenv.config();

// Import SQLite database
const db = require('./config/database_sqlite');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
};

// Auth routes
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    // Check if user already exists
    const existingUser = db.findUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = db.createUser({
      name,
      email,
      password: hashedPassword,
      phone
    });

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone
        }
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = db.findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
});

// Reminders routes
app.get('/api/reminders/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    // Verify user owns these reminders
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const reminders = db.getRemindersByUserId(userId);
    res.json({
      success: true,
      data: reminders
    });
  } catch (error) {
    console.error('Get reminders error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/reminders', authenticateToken, async (req, res) => {
  try {
    const { userId, title, description, dateTime } = req.body;

    // Verify user owns this reminder
    if (req.user.id !== parseInt(userId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const reminder = db.createReminder({
      user_id: userId,
      title,
      description,
      date_time: dateTime
    });

    res.status(201).json({
      success: true,
      message: 'Reminder created successfully',
      data: reminder
    });
  } catch (error) {
    console.error('Create reminder error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Health routes
app.get('/api/health/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const records = db.getHealthRecordsByUserId(userId);
    res.json({
      success: true,
      data: records
    });
  } catch (error) {
    console.error('Get health records error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/health', authenticateToken, async (req, res) => {
  try {
    const { userId, type, value, date, notes } = req.body;

    if (req.user.id !== parseInt(userId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const record = db.createHealthRecord({
      user_id: userId,
      type,
      value,
      date,
      notes
    });

    res.status(201).json({
      success: true,
      message: 'Health record created successfully',
      data: record
    });
  } catch (error) {
    console.error('Create health record error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Documents routes
app.get('/api/documents/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const docs = db.getDocumentsByUserId(userId);
    res.json({
      success: true,
      data: docs
    });
  } catch (error) {
    console.error('Get documents error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/documents', authenticateToken, async (req, res) => {
  try {
    const { userId, name, type, file_path, file_size, mime_type } = req.body;

    if (req.user.id !== parseInt(userId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const document = db.createDocument({
      user_id: userId,
      name,
      type,
      file_path,
      file_size,
      mime_type
    });

    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      data: document
    });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Family routes
app.get('/api/family/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const members = db.getFamilyMembersByUserId(userId);
    res.json({
      success: true,
      data: members
    });
  } catch (error) {
    console.error('Get family members error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/family', authenticateToken, async (req, res) => {
  try {
    const { userId, name, relation, phone, email, date_of_birth } = req.body;

    if (req.user.id !== parseInt(userId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const member = db.createFamilyMember({
      user_id: userId,
      name,
      relation,
      phone,
      email,
      date_of_birth
    });

    res.status(201).json({
      success: true,
      message: 'Family member added successfully',
      data: member
    });
  } catch (error) {
    console.error('Add family member error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Profile routes
app.get('/api/profile/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    if (req.user.id !== userId) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const user = db.findUserById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Remove password from response
    const { password, ...userWithoutPassword } = user;
    res.json({
      success: true,
      data: userWithoutPassword
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Database info endpoint
app.get('/api/database/info', (req, res) => {
  try {
    const db = require('./config/database_sqlite');
    const path = require('path');
    const fs = require('fs');
    
    const dbPath = path.join(__dirname, 'healthhive.db');
    const stats = fs.statSync(dbPath);
    
    res.json({
      success: true,
      data: {
        type: 'SQLite',
        path: dbPath,
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime,
        tables: ['users', 'reminders', 'health_records', 'documents', 'family_members']
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error getting database info' });
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'HealthHive API Running (SQLite Version)',
    version: '1.0.0',
    status: 'active',
    database: 'SQLite (persistent storage)',
    note: 'Data is stored in healthhive.db file'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server Error:', err);
  res.status(500).json({ 
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 5000;

// Start server
app.listen(PORT, () => {
  console.log(`🚀 HealthHive SQLite Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
  console.log(`💾 Database: SQLite (healthhive.db)`);
  console.log(`📝 Note: Users must register first before they can login`);
});
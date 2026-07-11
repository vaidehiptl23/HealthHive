const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const fileUpload = require('express-fileupload');

// Load environment variables
dotenv.config();

// Import database connection
const db = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const appointmentRoutes = require('./routes/reminders');
const documentRoutes = require('./routes/documents');
const heartRateRoutes = require('./routes/heart_rate');
const bloodPressureRoutes = require('./routes/blood_pressure');
const familyRoutes = require('./routes/family');
const medicineReminderRoutes = require('./routes/medicine_reminders');
const testReminderRoutes = require('./routes/test_reminders');
const chatRoutes = require('./routes/chat');
const notificationRoutes = require('./routes/notifications');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(fileUpload({
  limits: { fileSize: 10 * 1024 * 1024 },
  useTempFiles: false,
}));

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/reminders', appointmentRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/heart-rate', heartRateRoutes);
app.use('/api/blood-pressure', bloodPressureRoutes);
app.use('/api/family', familyRoutes);
app.use('/api/medicine-reminders', medicineReminderRoutes);
app.use('/api/test-reminders', testReminderRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/notifications', notificationRoutes);

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'HealthHive API Running with MySQL',
    version: '1.0.0',
    status: 'active'
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
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
});
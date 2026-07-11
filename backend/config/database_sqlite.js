const Database = require('better-sqlite3');
const path = require('path');
const bcrypt = require('bcryptjs');

// Create database file in the backend directory
const dbPath = path.join(__dirname, '..', 'healthhive.db');
const db = new Database(dbPath, { verbose: console.log });

console.log(`📊 SQLite Database: ${dbPath}`);

// Create tables if they don't exist
function initializeDatabase() {
  // Enable foreign keys
  db.pragma('foreign_keys = ON');

  // Users table
  db.prepare(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      phone TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `).run();

  // Reminders table
  db.prepare(`
    CREATE TABLE IF NOT EXISTS reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      date_time DATETIME NOT NULL,
      completed BOOLEAN DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `).run();

  // Health records table
  db.prepare(`
    CREATE TABLE IF NOT EXISTS health_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      value TEXT NOT NULL,
      date DATE NOT NULL,
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `).run();

  // Documents table
  db.prepare(`
    CREATE TABLE IF NOT EXISTS documents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      type TEXT,
      file_path TEXT,
      file_size INTEGER,
      mime_type TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `).run();

  // Family members table
  db.prepare(`
    CREATE TABLE IF NOT EXISTS family_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      relation TEXT,
      phone TEXT,
      email TEXT,
      date_of_birth DATE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `).run();

  console.log('✅ Database tables created/verified');

  // Check if database is empty
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get();
  if (userCount.count === 0) {
    console.log('📭 Database is empty. No users registered yet.');
    console.log('💡 Users must register first before they can login.');
  } else {
    console.log(`👥 Found ${userCount.count} registered user(s)`);
  }
}

// Initialize database
initializeDatabase();

// Database operations
const database = {
  // Users
  createUser: (userData) => {
    const stmt = db.prepare(`
      INSERT INTO users (name, email, password, phone)
      VALUES (?, ?, ?, ?)
    `);
    const info = stmt.run(userData.name, userData.email, userData.password, userData.phone);
    return { id: info.lastInsertRowid, ...userData };
  },

  findUserByEmail: (email) => {
    return db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  },

  findUserById: (id) => {
    return db.prepare('SELECT * FROM users WHERE id = ?').get(id);
  },

  // Reminders
  createReminder: (reminderData) => {
    const stmt = db.prepare(`
      INSERT INTO reminders (user_id, title, description, date_time)
      VALUES (?, ?, ?, ?)
    `);
    const info = stmt.run(
      reminderData.user_id,
      reminderData.title,
      reminderData.description,
      reminderData.date_time
    );
    return { id: info.lastInsertRowid, ...reminderData, completed: false };
  },

  getRemindersByUserId: (userId) => {
    return db.prepare('SELECT * FROM reminders WHERE user_id = ? ORDER BY date_time').all(userId);
  },

  // Health records
  createHealthRecord: (recordData) => {
    const stmt = db.prepare(`
      INSERT INTO health_records (user_id, type, value, date, notes)
      VALUES (?, ?, ?, ?, ?)
    `);
    const info = stmt.run(
      recordData.user_id,
      recordData.type,
      recordData.value,
      recordData.date,
      recordData.notes
    );
    return { id: info.lastInsertRowid, ...recordData };
  },

  getHealthRecordsByUserId: (userId) => {
    return db.prepare('SELECT * FROM health_records WHERE user_id = ? ORDER BY date DESC').all(userId);
  },

  // Documents
  createDocument: (docData) => {
    const stmt = db.prepare(`
      INSERT INTO documents (user_id, name, type, file_path, file_size, mime_type)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(
      docData.user_id,
      docData.name,
      docData.type,
      docData.file_path,
      docData.file_size,
      docData.mime_type
    );
    return { id: info.lastInsertRowid, ...docData };
  },

  getDocumentsByUserId: (userId) => {
    return db.prepare('SELECT * FROM documents WHERE user_id = ? ORDER BY created_at DESC').all(userId);
  },

  // Family members
  createFamilyMember: (memberData) => {
    const stmt = db.prepare(`
      INSERT INTO family_members (user_id, name, relation, phone, email, date_of_birth)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const info = stmt.run(
      memberData.user_id,
      memberData.name,
      memberData.relation,
      memberData.phone,
      memberData.email,
      memberData.date_of_birth
    );
    return { id: info.lastInsertRowid, ...memberData };
  },

  getFamilyMembersByUserId: (userId) => {
    return db.prepare('SELECT * FROM family_members WHERE user_id = ? ORDER BY name').all(userId);
  },

  // Close database connection
  close: () => {
    db.close();
  }
};

console.log('✅ SQLite database initialized and ready');

module.exports = database;
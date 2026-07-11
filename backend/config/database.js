const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'healthhive',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// Test database connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ MySQL Database Connected Successfully');
    console.log(`📊 Database: ${process.env.DB_NAME}`);
    console.log(`🏠 Host: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
    connection.release();
    
    // Create tables if they don't exist
    await createTables();
  } catch (error) {
    console.error('❌ Database Connection Error:', error.message);
    console.log('💡 Please check:');
    console.log('1. Is MySQL running?');
    console.log('2. Are database credentials correct in .env file?');
    console.log('3. Does the database "healthhive" exist?');
    process.exit(1);
  }
}

// Create database tables
async function createTables() {
  try {
    // Users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Users table created/verified');

    // Add subscription_plan safely if it doesn't exist
    try {
      await pool.query("ALTER TABLE users ADD COLUMN subscription_plan VARCHAR(20) DEFAULT 'free'");
      console.log('✅ Added subscription_plan column to users');
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error adding subscription_plan:', e);
    }

    // Add extended profile fields
    try {
      const q = "ALTER TABLE users ADD COLUMN first_name VARCHAR(100), ADD COLUMN middle_name VARCHAR(100), ADD COLUMN last_name VARCHAR(100), ADD COLUMN blood_group VARCHAR(10), ADD COLUMN gender VARCHAR(20), ADD COLUMN dob VARCHAR(50), ADD COLUMN height VARCHAR(20), ADD COLUMN weight VARCHAR(20), ADD COLUMN address TEXT";
      await pool.query(q);
      console.log('✅ Added extended profile columns to users');
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error adding extended profile columns:', e.message);
    }

    // Add emergency detail fields
    try {
      await pool.query("ALTER TABLE users ADD COLUMN emergency_contact_name VARCHAR(100), ADD COLUMN emergency_contact_phone VARCHAR(20), ADD COLUMN emergency_blood_group VARCHAR(10), ADD COLUMN allergies TEXT, ADD COLUMN existing_conditions TEXT");
      console.log('✅ Added emergency detail columns to users');
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error adding emergency columns:', e.message);
    }

    // OTP table for forgot password
    await pool.query(`
      CREATE TABLE IF NOT EXISTS password_otps (
        id INT PRIMARY KEY AUTO_INCREMENT,
        email VARCHAR(100) NOT NULL,
        otp VARCHAR(10) NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Password OTPs table created/verified');

    // Family members table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS family_members (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        first_name VARCHAR(100) NOT NULL,
        middle_name VARCHAR(100),
        last_name VARCHAR(100) NOT NULL,
        email VARCHAR(100),
        blood_group VARCHAR(10),
        gender VARCHAR(20),
        phone VARCHAR(20),
        dob VARCHAR(50),
        height VARCHAR(20),
        weight VARCHAR(20),
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Family members table created/verified');

    // Migrate old family_members table if needed
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN first_name VARCHAR(100)");
      await pool.query("UPDATE family_members SET first_name = name WHERE first_name IS NULL OR first_name = ''");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating first_name:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN middle_name VARCHAR(100)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating middle_name:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN last_name VARCHAR(100)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating last_name:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN blood_group VARCHAR(10)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating blood_group:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN gender VARCHAR(20)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating gender:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN dob VARCHAR(50)");
      await pool.query("UPDATE family_members SET dob = CAST(date_of_birth AS CHAR) WHERE date_of_birth IS NOT NULL");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating dob:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN height VARCHAR(20)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating height:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN weight VARCHAR(20)");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating weight:', e.message);
    }
    
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN address TEXT");
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error migrating address:', e.message);
    }

    // Add emergency detail fields to family members
    try {
      await pool.query("ALTER TABLE family_members ADD COLUMN emergency_contact_name VARCHAR(100), ADD COLUMN emergency_contact_phone VARCHAR(20), ADD COLUMN emergency_blood_group VARCHAR(10), ADD COLUMN allergies TEXT, ADD COLUMN existing_conditions TEXT");
      console.log('✅ Added emergency detail columns to family members');
    } catch (e) {
      if (e.code !== 'ER_DUP_FIELDNAME') console.error('Error adding family emergency columns:', e.message);
    }

    // Appointment reminders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS appointment_reminders (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        place VARCHAR(200),
        date VARCHAR(100),
        time VARCHAR(100),
        purpose VARCHAR(300),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    `);
    console.log('✅ Appointment reminders table created/verified');

    // Medicine reminders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS medicine_reminders (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        name VARCHAR(200) NOT NULL,
        dose VARCHAR(100),
        meal VARCHAR(100),
        morning BOOLEAN DEFAULT FALSE,
        morning_time VARCHAR(20),
        afternoon BOOLEAN DEFAULT FALSE,
        afternoon_time VARCHAR(20),
        night BOOLEAN DEFAULT FALSE,
        night_time VARCHAR(20),
        repeat_days VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    `);
    console.log('✅ Medicine reminders table created/verified');

    // Test reminders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS test_reminders (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        name VARCHAR(200) NOT NULL,
        meal VARCHAR(100),
        morning BOOLEAN DEFAULT FALSE,
        morning_time VARCHAR(20),
        afternoon BOOLEAN DEFAULT FALSE,
        afternoon_time VARCHAR(20),
        night BOOLEAN DEFAULT FALSE,
        night_time VARCHAR(20),
        repeat_days VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    `);
    console.log('✅ Test reminders table created/verified');

    // Heart rate table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS heart_rate (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        bpm INT NOT NULL,
        recorded_at DATETIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_recorded_at (recorded_at)
      )
    `);
    console.log('✅ Heart rate table created/verified');

    // Blood pressure table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS blood_pressure (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        systolic INT NOT NULL,
        diastolic INT NOT NULL,
        recorded_at DATETIME NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_recorded_at (recorded_at)
      )
    `);
    console.log('✅ Blood pressure table created/verified');

    // Documents table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50),
        category VARCHAR(100),
        upload_for VARCHAR(100),
        note TEXT,
        file_url VARCHAR(500),
        cloudinary_id VARCHAR(255),
        file_size INT,
        mime_type VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    `);
    console.log('✅ Documents table created/verified');

    // Notifications table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id INT NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    `);
    console.log('✅ Notifications table created/verified');

    console.log('🎉 All database tables are ready!');
  } catch (error) {
    console.error('❌ Error creating tables:', error.message);
  }
}

// Test connection on startup
testConnection();

module.exports = pool;
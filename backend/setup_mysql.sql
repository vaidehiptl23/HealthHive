-- HealthHive MySQL Database Setup Script
-- Run this script in MySQL to create the database and user

-- 1. Create database
CREATE DATABASE IF NOT EXISTS healthhive;
USE healthhive;

-- 2. Create tables (these will also be created automatically by the app)
-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Reminders table
CREATE TABLE IF NOT EXISTS reminders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  date_time DATETIME NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_date_time (date_time)
);

-- Health records table
CREATE TABLE IF NOT EXISTS health_records (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  type VARCHAR(100) NOT NULL,
  value VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_date (date)
);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  type VARCHAR(50),
  file_path VARCHAR(500),
  file_size INT,
  mime_type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- Family members table
CREATE TABLE IF NOT EXISTS family_members (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  relation VARCHAR(50),
  phone VARCHAR(20),
  email VARCHAR(100),
  date_of_birth DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- 3. Insert sample data (optional)
-- Sample user (password: password123)
INSERT INTO users (name, email, password, phone) VALUES
('John Doe', 'john@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye3Z4L3B.3H.5JZ.6YVYQz7z1V2V2V2V2', '1234567890')
ON DUPLICATE KEY UPDATE name = name;

-- Get the user ID
SET @user_id = (SELECT id FROM users WHERE email = 'john@example.com');

-- Sample reminders
INSERT INTO reminders (user_id, title, description, date_time) VALUES
(@user_id, 'Take Medicine', 'Blood pressure medication', DATE_ADD(NOW(), INTERVAL 2 HOUR)),
(@user_id, 'Doctor Appointment', 'Annual checkup', DATE_ADD(NOW(), INTERVAL 1 DAY)),
(@user_id, 'Blood Test', 'Fasting required', DATE_ADD(NOW(), INTERVAL 3 DAY))
ON DUPLICATE KEY UPDATE title = title;

-- Sample health records
INSERT INTO health_records (user_id, type, value, date, notes) VALUES
(@user_id, 'Blood Pressure', '120/80', CURDATE() - INTERVAL 1 DAY, 'Morning reading'),
(@user_id, 'Blood Sugar', '95', CURDATE() - INTERVAL 2 DAY, 'Fasting'),
(@user_id, 'Weight', '70 kg', CURDATE(), 'After breakfast')
ON DUPLICATE KEY UPDATE value = value;

-- Sample family members
INSERT INTO family_members (user_id, name, relation, phone) VALUES
(@user_id, 'Jane Doe', 'Wife', '0987654321'),
(@user_id, 'Mike Doe', 'Son', '1122334455')
ON DUPLICATE KEY UPDATE name = name;

-- 4. Show created tables
SHOW TABLES;

-- 5. Show table structure
DESCRIBE users;
DESCRIBE reminders;
DESCRIBE health_records;
DESCRIBE documents;
DESCRIBE family_members;

-- 6. Show sample data
SELECT 'Users:' AS '';
SELECT id, name, email, phone FROM users;

SELECT 'Reminders:' AS '';
SELECT id, title, date_time, completed FROM reminders WHERE user_id = @user_id;

SELECT 'Health Records:' AS '';
SELECT id, type, value, date FROM health_records WHERE user_id = @user_id;

SELECT 'Family Members:' AS '';
SELECT id, name, relation, phone FROM family_members WHERE user_id = @user_id;

-- 7. Create a dedicated database user (optional)
-- CREATE USER 'healthhive_user'@'localhost' IDENTIFIED BY 'secure_password';
-- GRANT ALL PRIVILEGES ON healthhive.* TO 'healthhive_user'@'localhost';
-- FLUSH PRIVILEGES;
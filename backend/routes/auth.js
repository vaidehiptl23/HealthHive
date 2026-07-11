const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const authMiddleware = require('../middleware/auth');

// Register new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Name, email and password are required' 
      });
    }

    // Check if user already exists
    const [existingUser] = await pool.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert user
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, phone) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, phone || null]
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId: result.insertId, email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        token,
        user: {
          id: result.insertId,
          name,
          email,
          phone: phone || null
        }
      }
    });

    // Add welcome notification
    await pool.query(
      `INSERT INTO notifications (user_id, message) VALUES (?, ?)`,
      [result.insertId, '👋 Welcome to HealthHive! We are excited to help you start managing your health journey.']
    );

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user
    const [users] = await pool.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const user = users[0];

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
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
          phone: user.phone,
          subscription_plan: user.subscription_plan
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// Get current user profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const [users] = await pool.query('SELECT id, name, first_name, middle_name, last_name, email, phone, blood_group, gender, dob, height, weight, address, subscription_plan FROM users WHERE id = ?', [req.userId]);
    if (users.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
    
    res.json({
      success: true,
      data: { user: users[0] }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update user profile
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { first_name, middle_name, last_name, phone, blood_group, gender, dob, height, weight, address } = req.body;
    
    // Automatically assemble the full name
    const fullName = [first_name, last_name].filter(Boolean).join(' ') || 'User';

    await pool.query(
      `UPDATE users SET name = ?, first_name = ?, middle_name = ?, last_name = ?, phone = ?, blood_group = ?, gender = ?, dob = ?, height = ?, weight = ?, address = ? WHERE id = ?`,
      [fullName, first_name, middle_name, last_name, phone, blood_group, gender, dob, height, weight, address, req.userId]
    );

    res.json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Upgrade Subscription explicitly in Auth for quick demo mocking
router.put('/upgrade', authMiddleware, async (req, res) => {
  try {
    const { plan } = req.body;
    if (!['free', 'plus', 'premium'].includes(plan)) {
      return res.status(400).json({ success: false, message: 'Invalid plan selected' });
    }
    
    await pool.query('UPDATE users SET subscription_plan = ? WHERE id = ?', [plan, req.userId]);
    res.json({ success: true, message: 'Subscription successfully upgraded to ' + plan, plan });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error during upgrade' });
  }
});

// ─── EMERGENCY DETAILS ──────────────────────────────────────────────────────

// Get emergency details
router.get('/emergency', authMiddleware, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT emergency_contact_name, emergency_contact_phone, emergency_blood_group, allergies, existing_conditions FROM users WHERE id = ?',
      [req.userId]
    );
    if (users.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: users[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update emergency details
router.put('/emergency', authMiddleware, async (req, res) => {
  try {
    const { emergency_contact_name, emergency_contact_phone, emergency_blood_group, allergies, existing_conditions } = req.body;
    await pool.query(
      'UPDATE users SET emergency_contact_name = ?, emergency_contact_phone = ?, emergency_blood_group = ?, allergies = ?, existing_conditions = ? WHERE id = ?',
      [emergency_contact_name, emergency_contact_phone, emergency_blood_group, allergies, existing_conditions, req.userId]
    );
    res.json({ success: true, message: 'Emergency details saved successfully' });
  } catch (error) {
    console.error('Update emergency error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ─── FORGOT PASSWORD FLOW ──────────────────────────────────────────────────

const nodemailer = require('nodemailer');

// Create reusable transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Send OTP to email
router.post('/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email is required' });

    // Check if user exists
    const [users] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(404).json({ success: false, message: 'No account found with this email' });
    }

    // Generate 4-digit OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    // Expire in 5 minutes
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    // Invalidate any previous OTPs for this email
    await pool.query('UPDATE password_otps SET used = TRUE WHERE email = ? AND used = FALSE', [email]);

    // Store OTP
    await pool.query('INSERT INTO password_otps (email, otp, expires_at) VALUES (?, ?, ?)', [email, otp, expiresAt]);

    // Send email
    await transporter.sendMail({
      from: `"HealthHive" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'HealthHive - Password Reset OTP',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 30px; background: #f5f5f5; border-radius: 16px;">
          <h2 style="color: #2E7D32; text-align: center;">🔒 Password Reset</h2>
          <p style="text-align: center; color: #555;">Your verification code is:</p>
          <div style="text-align: center; margin: 20px 0;">
            <span style="background: #2E7D32; color: white; padding: 12px 30px; border-radius: 10px; font-size: 28px; letter-spacing: 8px; font-weight: bold;">${otp}</span>
          </div>
          <p style="text-align: center; color: #999; font-size: 13px;">This code expires in 5 minutes. Do not share it with anyone.</p>
        </div>
      `,
    });

    console.log(`📧 OTP ${otp} sent to ${email}`);
    res.json({ success: true, message: 'OTP sent to your email' });
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ success: false, message: 'Failed to send OTP. Check email configuration.' });
  }
});

// Verify OTP
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: 'Email and OTP are required' });

    const [rows] = await pool.query(
      'SELECT * FROM password_otps WHERE email = ? AND otp = ? AND used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [email, otp]
    );

    if (rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    // Mark OTP as used
    await pool.query('UPDATE password_otps SET used = TRUE WHERE id = ?', [rows[0].id]);

    // Generate a temporary reset token
    const resetToken = jwt.sign({ email, purpose: 'reset' }, process.env.JWT_SECRET, { expiresIn: '10m' });

    res.json({ success: true, message: 'OTP verified successfully', resetToken });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Reset password (after OTP verification)
router.post('/reset-password', async (req, res) => {
  try {
    const { resetToken, newPassword } = req.body;
    if (!resetToken || !newPassword) return res.status(400).json({ success: false, message: 'Reset token and new password are required' });

    // Verify the reset token
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
      if (decoded.purpose !== 'reset') throw new Error('Invalid token purpose');
    } catch (e) {
      return res.status(401).json({ success: false, message: 'Invalid or expired reset token. Please restart the process.' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await pool.query('UPDATE users SET password = ? WHERE email = ?', [hashedPassword, decoded.email]);

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
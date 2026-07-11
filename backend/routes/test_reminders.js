const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET all test reminders for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM test_reminders WHERE user_id = ? ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get test reminders error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST save a test reminder
router.post('/', auth, async (req, res) => {
  try {
    const { name, meal, morning, morning_time, afternoon, afternoon_time, night, night_time, repeat_days } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'name is required' });
    const [result] = await pool.query(
      `INSERT INTO test_reminders (user_id, name, meal, morning, morning_time, afternoon, afternoon_time, night, night_time, repeat_days)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.userId, name, meal || null,
       morning ? 1 : 0, morning_time || null,
       afternoon ? 1 : 0, afternoon_time || null,
       night ? 1 : 0, night_time || null,
       repeat_days ? repeat_days.join(',') : null]
    );

    // Insert into notifications history table
    const reminderMsg = `🧪 Health test reminder set: ${name} - ${meal || 'No meal dependency'}`;
    await pool.query(
      `INSERT INTO notifications (user_id, message) VALUES (?, ?)`,
      [req.userId, reminderMsg.trim()]
    );

    const [row] = await pool.query('SELECT * FROM test_reminders WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: row[0] });
  } catch (err) {
    console.error('Save test reminder error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

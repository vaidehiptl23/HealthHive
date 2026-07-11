const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// Get all health records for logged-in user only
router.get('/', auth, async (req, res) => {
  try {
    const [records] = await pool.query(
      `SELECT * FROM health_records WHERE user_id = ? ORDER BY recorded_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: records });
  } catch (error) {
    console.error('Get health records error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Create health record for logged-in user
router.post('/', auth, async (req, res) => {
  try {
    const { type, value, recorded_at } = req.body;
    if (!type || !value) {
      return res.status(400).json({ success: false, message: 'type and value are required' });
    }
    // Accept both ISO 8601 and MySQL datetime formats
    let recordedAt;
    if (recorded_at) {
      // Convert ISO 8601 to MySQL datetime if needed
      const d = new Date(recorded_at);
      recordedAt = d.toISOString().slice(0, 19).replace('T', ' ');
    } else {
      recordedAt = new Date().toISOString().slice(0, 19).replace('T', ' ');
    }
    const [result] = await pool.query(
      `INSERT INTO health_records (user_id, type, value, recorded_at) VALUES (?, ?, ?, ?)`,
      [req.userId, type, value, recordedAt]
    );
    const [newRecord] = await pool.query('SELECT * FROM health_records WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: newRecord[0] });
  } catch (error) {
    console.error('Create health record error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

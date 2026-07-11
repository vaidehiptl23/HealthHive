const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

function toMysqlDatetime(val) {
  const d = val ? new Date(val) : new Date();
  return d.toISOString().slice(0, 19).replace('T', ' ');
}

// GET all heart rate records for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM heart_rate WHERE user_id = ? ORDER BY recorded_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get heart rate error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST save a heart rate reading
router.post('/', auth, async (req, res) => {
  try {
    const { bpm, recorded_at } = req.body;
    if (!bpm) return res.status(400).json({ success: false, message: 'bpm is required' });
    const recordedAt = toMysqlDatetime(recorded_at);
    const [result] = await pool.query(
      `INSERT INTO heart_rate (user_id, bpm, recorded_at) VALUES (?, ?, ?)`,
      [req.userId, bpm, recordedAt]
    );
    const [row] = await pool.query('SELECT * FROM heart_rate WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: row[0] });
  } catch (err) {
    console.error('Save heart rate error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

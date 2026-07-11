const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

function toMysqlDatetime(val) {
  const d = val ? new Date(val) : new Date();
  return d.toISOString().slice(0, 19).replace('T', ' ');
}

// GET all blood pressure records for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM blood_pressure WHERE user_id = ? ORDER BY recorded_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get blood pressure error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST save a blood pressure reading
router.post('/', auth, async (req, res) => {
  try {
    const { systolic, diastolic, recorded_at } = req.body;
    if (!systolic || !diastolic) {
      return res.status(400).json({ success: false, message: 'systolic and diastolic are required' });
    }
    const recordedAt = toMysqlDatetime(recorded_at);
    const [result] = await pool.query(
      `INSERT INTO blood_pressure (user_id, systolic, diastolic, recorded_at) VALUES (?, ?, ?, ?)`,
      [req.userId, systolic, diastolic, recordedAt]
    );
    const [row] = await pool.query('SELECT * FROM blood_pressure WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: row[0] });
  } catch (err) {
    console.error('Save blood pressure error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

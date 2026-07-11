const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET all appointment reminders for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM appointment_reminders WHERE user_id = ? ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get appointment reminders error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST save an appointment reminder
router.post('/', auth, async (req, res) => {
  try {
    const { place, date, time, purpose } = req.body;
    if (!date) return res.status(400).json({ success: false, message: 'date is required' });
    const [result] = await pool.query(
      `INSERT INTO appointment_reminders (user_id, place, date, time, purpose) VALUES (?, ?, ?, ?, ?)`,
      [req.userId, place || null, date, time || null, purpose || null]
    );
    
    // Insert into notifications history table
    const reminderMsg = `📅 Appointment set: ${purpose || 'Doctor Appointment'} at ${place || 'clinic'} on ${date} ${time || ''}`;
    await pool.query(
      `INSERT INTO notifications (user_id, message) VALUES (?, ?)`,
      [req.userId, reminderMsg.trim()]
    );

    const [row] = await pool.query('SELECT * FROM appointment_reminders WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: row[0] });
  } catch (err) {
    console.error('Save appointment reminder error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// DELETE an appointment reminder
router.delete('/:id', auth, async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM appointment_reminders WHERE id = ? AND user_id = ?',
      [req.params.id, req.userId]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Not found' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (err) {
    console.error('Delete appointment reminder error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

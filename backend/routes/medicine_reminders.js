const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET all medicine reminders for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM medicine_reminders WHERE user_id = ? ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get medicine reminders error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST save a medicine reminder
router.post('/', auth, async (req, res) => {
  try {
    const { name, dose, meal, morning, morning_time, afternoon, afternoon_time, night, night_time, repeat_days } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'name is required' });
    const [result] = await pool.query(
      `INSERT INTO medicine_reminders (user_id, name, dose, meal, morning, morning_time, afternoon, afternoon_time, night, night_time, repeat_days)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.userId, name, dose || null, meal || null,
       morning ? 1 : 0, morning_time || null,
       afternoon ? 1 : 0, afternoon_time || null,
       night ? 1 : 0, night_time || null,
       repeat_days ? repeat_days.join(',') : null]
    );

    // Insert into notifications history table
    const reminderMsg = `💊 Medicine reminder set: Take ${name} ${dose ? `(${dose})` : ''} - ${meal || 'No meal dependency'}`;
    await pool.query(
      `INSERT INTO notifications (user_id, message) VALUES (?, ?)`,
      [req.userId, reminderMsg.trim()]
    );

    const [row] = await pool.query('SELECT * FROM medicine_reminders WHERE id = ?', [result.insertId]);
    res.status(201).json({ success: true, data: row[0] });
  } catch (err) {
    console.error('Save medicine reminder error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST check drug interaction
router.post('/check-interaction', auth, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Medicine name is required' });
    }

    if (!process.env.GEMINI_API_KEY) {
      return res.json({ success: true, interaction: 'NO_INTERACTION' });
    }

    const [existingRows] = await pool.query(
      `SELECT DISTINCT name FROM medicine_reminders WHERE user_id = ?`,
      [req.userId]
    );

    if (existingRows.length === 0) {
      return res.json({ success: true, interaction: 'NO_INTERACTION' });
    }

    const newMed = name.trim();
    const activeMeds = existingRows.map(r => r.name).join(', ');

    console.log(`🔮 Checking drug interaction between new medicine: ${newMed} and existing: ${activeMeds}`);

    const promptText = `You are a professional clinical pharmacist AI. 
Analyze if there are any high-risk, dangerous drug-to-drug interactions between:
New Medicine: ${newMed}
Existing active medicines currently taken by the patient: ${activeMeds}

Strict output format:
1. If there is a high-risk or moderate interaction that the patient must be warned about, start your response exactly with "WARNING: " followed by a brief, plain-English explanation (max 2-3 sentences) of the risk and what they should do.
2. If there are no dangerous or clinically significant interactions, respond with exactly "NO_INTERACTION".
Keep the explanation clear, patient-friendly, and very concise.`;

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: promptText }]
            }
          ]
        })
      }
    );

    if (!geminiRes.ok) {
      console.error('Gemini API Error checking interaction:', await geminiRes.text());
      return res.json({ success: true, interaction: 'NO_INTERACTION' });
    }

    const geminiData = await geminiRes.json();
    const reply = (geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'NO_INTERACTION').trim();
    
    console.log('🔮 Gemini Drug Interaction Result:', reply);

    res.json({ success: true, interaction: reply });

  } catch (err) {
    console.error('Check drug interaction error:', err);
    res.json({ success: true, interaction: 'NO_INTERACTION' });
  }
});

module.exports = router;

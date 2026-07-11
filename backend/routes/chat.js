const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama3';

// POST /api/chat
router.post('/', auth, async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    // ── Fetch user health context from DB ─────────────────────

    // Recent heart rate (last 5)
    const [hrRows] = await pool.query(
      `SELECT bpm, recorded_at FROM heart_rate WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 5`,
      [req.userId]
    );

    // Recent blood pressure (last 5)
    const [bpRows] = await pool.query(
      `SELECT systolic, diastolic, recorded_at FROM blood_pressure WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 5`,
      [req.userId]
    );

    // Active appointment reminders
    const [apptRows] = await pool.query(
      `SELECT place, date, time, purpose FROM appointment_reminders WHERE user_id = ? ORDER BY created_at DESC LIMIT 5`,
      [req.userId]
    );

    // Active medicine reminders
    const [medRows] = await pool.query(
      `SELECT name, dose, meal, morning, afternoon, night FROM medicine_reminders WHERE user_id = ? ORDER BY created_at DESC LIMIT 5`,
      [req.userId]
    );

    // Active test reminders
    const [testRows] = await pool.query(
      `SELECT name, meal, morning, afternoon, night FROM test_reminders WHERE user_id = ? ORDER BY created_at DESC LIMIT 5`,
      [req.userId]
    );

    // ── Build context string ──────────────────────────────────

    let context = '';

    if (hrRows.length > 0) {
      context += '\n[Heart Rate History]\n';
      hrRows.forEach(r => {
        context += `  - ${r.bpm} bpm on ${r.recorded_at}\n`;
      });
    }

    if (bpRows.length > 0) {
      context += '\n[Blood Pressure History]\n';
      bpRows.forEach(r => {
        context += `  - ${r.systolic}/${r.diastolic} mmHg on ${r.recorded_at}\n`;
      });
    }

    if (apptRows.length > 0) {
      context += '\n[Upcoming Appointments]\n';
      apptRows.forEach(r => {
        context += `  - ${r.purpose || 'Appointment'}${r.place ? ' at ' + r.place : ''}${r.date ? ' on ' + r.date : ''}${r.time ? ' at ' + r.time : ''}\n`;
      });
    }

    if (medRows.length > 0) {
      context += '\n[Current Medicines]\n';
      medRows.forEach(r => {
        const times = [r.morning ? 'morning' : '', r.afternoon ? 'afternoon' : '', r.night ? 'night' : ''].filter(Boolean).join(', ');
        context += `  - ${r.name}${r.dose ? ' (' + r.dose + ')' : ''}${r.meal ? ' - ' + r.meal : ''}${times ? ' | Times: ' + times : ''}\n`;
      });
    }

    if (testRows.length > 0) {
      context += '\n[Scheduled Tests]\n';
      testRows.forEach(r => {
        const times = [r.morning ? 'morning' : '', r.afternoon ? 'afternoon' : '', r.night ? 'night' : ''].filter(Boolean).join(', ');
        context += `  - ${r.name}${r.meal ? ' - ' + r.meal : ''}${times ? ' | Times: ' + times : ''}\n`;
      });
    }

    if (!context) {
      context = '\n[No health records available yet for this user]\n';
    }

    // ── System prompt ─────────────────────────────────────────

    const systemPrompt = `You are HealthHive AI, a health assistant embedded in a personal health management app.

STRICT RULES:
1. ONLY respond to health-related questions (symptoms, medicines, diet, exercise, vitals, medical appointments, wellness).
2. If the user asks something NOT related to health, politely decline: "I can only help with health-related questions. Please ask me about your health, medicines, vitals, or wellness."
3. Keep responses SHORT (2-4 sentences max). Be concise and meaningful.
4. Use the patient's health data below to personalize your answers when relevant.
5. Never diagnose or prescribe. Always suggest consulting a doctor for serious concerns.
6. Be warm, friendly, and supportive.

PATIENT HEALTH DATA:
${context}

Remember: Short, focused, health-only responses using the patient data above when relevant.`;

    // ── Call Ollama ────────────────────────────────────────────

    const ollamaRes = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt: message,
        system: systemPrompt,
        stream: false,
      }),
    });

    if (!ollamaRes.ok) {
      const errText = await ollamaRes.text();
      console.error('Ollama error:', ollamaRes.status, errText);
      return res.status(502).json({ success: false, message: 'AI service unavailable. Make sure Ollama is running.' });
    }

    const ollamaData = await ollamaRes.json();
    const reply = ollamaData.response || 'Sorry, I could not generate a response.';

    res.json({ success: true, reply });

  } catch (err) {
    console.error('Chat error:', err.message);
    if (err.cause && err.cause.code === 'ECONNREFUSED') {
      return res.status(502).json({ success: false, message: 'Cannot connect to Ollama. Please make sure Ollama is running on your machine.' });
    }
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

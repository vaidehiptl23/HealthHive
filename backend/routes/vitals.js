const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET /api/vitals/trends
router.get('/trends', auth, async (req, res) => {
  try {
    // Fetch last 30 heart rate logs
    const [hrRows] = await pool.query(
      `SELECT bpm, recorded_at FROM heart_rate WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 30`,
      [req.userId]
    );

    // Fetch last 30 blood pressure logs
    const [bpRows] = await pool.query(
      `SELECT systolic, diastolic, recorded_at FROM blood_pressure WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 30`,
      [req.userId]
    );

    if (hrRows.length === 0 && bpRows.length === 0) {
      return res.json({ 
        success: true, 
        trends: "No vitals logs recorded yet. Please log your Heart Rate and Blood Pressure first to enable AI trend analysis!" 
      });
    }

    if (!process.env.GEMINI_API_KEY) {
      return res.status(400).json({ success: false, message: 'Gemini API Key is not configured on the server.' });
    }

    // Build the vitals log context
    let logText = "";
    if (hrRows.length > 0) {
      logText += "\n--- HEART RATE LOGS (Last 30) ---\n";
      hrRows.forEach(r => {
        logText += `- ${r.bpm} bpm at ${r.recorded_at}\n`;
      });
    }

    if (bpRows.length > 0) {
      logText += "\n--- BLOOD PRESSURE LOGS (Last 30) ---\n";
      bpRows.forEach(r => {
        logText += `- ${r.systolic}/${r.diastolic} mmHg at ${r.recorded_at}\n`;
      });
    }

    console.log(`🔮 Running vitals trends analysis using Gemini AI...`);

    const promptText = `You are a professional cardiology and health wellness coach AI assistant. 
Analyze the following patient vital history logs:
${logText}

Generate a clear, patient-friendly Vital Trend Report containing:
1. Average vitals summary (Averages, ranges, and classification like normal, elevated, hypertensive).
2. Key observations: highlight any alarming spikes, patterns, or anomalies (e.g. spikes at specific times of day, heart rate elevations).
3. Actionable lifestyle, stress-management, sleep, or dietary tips to stabilize or improve these vitals.
4. End with a strong medical disclaimer stating that this AI analysis is for informational purposes only and not a substitute for professional medical care.

Format using clean Markdown with clear headings and bullet points.`;

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
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
      console.error('Gemini API Error vitals check:', await geminiRes.text());
      return res.status(502).json({ success: false, message: 'Gemini AI service error' });
    }

    const geminiData = await geminiRes.json();
    const trends = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'Could not compile vital trends.';

    res.json({ success: true, trends });

  } catch (err) {
    console.error('Get vitals trends error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

function toMysqlDatetime(val) {
  const d = val ? new Date(val) : new Date();
  return d.toISOString().slice(0, 19).replace('T', ' ');
}

// POST /api/vitals/voice-log
router.post('/voice-log', auth, async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Speech text is required.' });
    }

    if (!process.env.GEMINI_API_KEY) {
      return res.status(400).json({ success: false, message: 'Gemini API Key is not configured.' });
    }

    console.log(`🔮 Voice parsing text: "${text}" using Gemini AI...`);

    const promptText = `You are a professional medical assistant interface. Parse the following transcription of a patient logging their vitals:
"${text}"

Extract the vitals values and categorize them into one of these types:
1. "heart_rate" (if they log heart rate, pulse, or bpm). Extract: "bpm" (integer).
2. "blood_pressure" (if they log blood pressure, BP, systolic/diastolic). Extract: "systolic" (integer), "diastolic" (integer).
3. "unknown" (if it doesn't contain these vitals).

You must respond with a strict JSON object only. Do not wrap it in markdown code blocks or add extra text.
Format:
{
  "type": "heart_rate" | "blood_pressure" | "unknown",
  "data": {
    "bpm": 72
  }
}
OR for blood_pressure:
{
  "type": "blood_pressure",
  "data": {
    "systolic": 120,
    "diastolic": 80
  }
}`;

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
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
      console.error('Gemini API Error voice-log:', await geminiRes.text());
      return res.status(502).json({ success: false, message: 'Gemini AI service error' });
    }

    const geminiData = await geminiRes.json();
    let rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    
    // Clean up markdown blocks if Gemini accidentally returned them
    rawText = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
    
    const parsed = JSON.parse(rawText);
    const { type, data } = parsed;

    if (type === 'heart_rate' && data && data.bpm) {
      await pool.query(
        `INSERT INTO heart_rate (user_id, bpm, recorded_at) VALUES (?, ?, ?)`,
        [req.userId, data.bpm, toMysqlDatetime()]
      );
      return res.json({ 
        success: true, 
        message: `Successfully logged Heart Rate: ${data.bpm} bpm.` 
      });
    }

    if (type === 'blood_pressure' && data && data.systolic && data.diastolic) {
      await pool.query(
        `INSERT INTO blood_pressure (user_id, systolic, diastolic, recorded_at) VALUES (?, ?, ?, ?)`,
        [req.userId, data.systolic, data.diastolic, toMysqlDatetime()]
      );
      return res.json({ 
        success: true, 
        message: `Successfully logged Blood Pressure: ${data.systolic}/${data.diastolic} mmHg.` 
      });
    }

    res.json({ 
      success: false, 
      message: "Could not recognize any Heart Rate or Blood Pressure readings in that phrase. Please try saying: 'My blood pressure is 120 over 80' or 'Heart rate is 75'." 
    });

  } catch (err) {
    console.error('Voice log error:', err);
    res.status(500).json({ success: false, message: 'Server error processing your speech.' });
  }
});

module.exports = router;

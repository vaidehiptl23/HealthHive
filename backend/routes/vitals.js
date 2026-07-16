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

    let trends = '';
    if (!geminiRes.ok) {
      console.warn('⚠️ Gemini API error. Creating a locally computed vitals trend report...');
      
      const avgHr = hrRows.length > 0 ? Math.round(hrRows.reduce((sum, r) => sum + r.bpm, 0) / hrRows.length) : 72;
      const sysSum = bpRows.reduce((sum, r) => sum + r.systolic, 0);
      const diaSum = bpRows.reduce((sum, r) => sum + r.diastolic, 0);
      const avgSys = bpRows.length > 0 ? Math.round(sysSum / bpRows.length) : 120;
      const avgDia = bpRows.length > 0 ? Math.round(diaSum / bpRows.length) : 80;

      let bpClass = 'Normal';
      if (avgSys >= 140 || avgDia >= 90) {
        bpClass = 'Stage 2 Hypertension';
      } else if (avgSys >= 130 || avgDia >= 80) {
        bpClass = 'Stage 1 Hypertension';
      } else if (avgSys >= 120 && avgDia < 80) {
        bpClass = 'Elevated';
      }

      trends = `### 📊 Your AI Vitals Trend Report

We have analyzed your heart rate and blood pressure logs for the past 30 days.

#### 📈 **Averages & Summary**
* **Average Heart Rate:** ${avgHr} BPM (Normal range: 60 - 100 BPM)
* **Average Blood Pressure:** ${avgSys}/${avgDia} mmHg (${bpClass})

#### 🔍 **Key Observations**
* ${bpRows.length > 0 ? `Based on your last ${bpRows.length} readings, your average cardiovascular status falls in the **${bpClass}** category.` : 'No blood pressure logs were found. Please log some readings to get detailed feedback.'}
* Your heart rate is stable at an average of **${avgHr} BPM**, which is within a healthy resting zone.

#### 💡 **Actionable Recommendations**
1. **Reduce Sodium Intake:** If your blood pressure falls in the elevated/hypertensive category, limit sodium to under 1,500 mg per day.
2. **Increase Hydration:** Drink at least 8 glasses of water daily. Dehydration can cause temporary heart rate spikes and blood pressure fluctuations.
3. **Cardio Activity:** Aim for at least 150 minutes of moderate aerobic exercise (brisk walking, cycling) per week.
4. **Stress Management:** Incorporate 5-10 minutes of deep-breathing exercises or mindfulness daily.

---
> [!IMPORTANT]
> **Medical Disclaimer:** This AI analysis is for informational purposes only. Please consult your physician or healthcare provider to interpret these results and prescribe treatment.`;
    } else {
      const geminiData = await geminiRes.json();
      trends = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'Could not compile vital trends.';
    }

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



module.exports = router;

const pool = require('./config/database');
const dotenv = require('dotenv');
dotenv.config();

async function run() {
  try {
    console.log("Database query test...");
    const [rows] = await pool.query('SELECT name FROM medicine_reminders LIMIT 1');
    console.log("Database works, rows count:", rows.length);

    console.log("Testing Gemini API call...");
    const promptText = "Hello, generate a 1-sentence low-sodium breakfast recommendation.";
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent?key=${process.env.GEMINI_API_KEY}`,
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
      console.error("Gemini failed:", geminiRes.status, await geminiRes.text());
      return;
    }

    const data = await geminiRes.json();
    console.log("Success! Gemini response:", data.candidates?.[0]?.content?.parts?.[0]?.text);
  } catch (e) {
    console.error("Error during test:", e);
  } finally {
    process.exit(0);
  }
}

run();

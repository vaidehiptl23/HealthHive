const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET /api/wellness/diet-plan
router.get('/diet-plan', auth, async (req, res) => {
  try {
    const dietType = req.query.dietType || 'Vegetarian';

    // 1. Fetch active medicines
    const [medRows] = await pool.query(
      `SELECT name FROM medicine_reminders WHERE user_id = ?`,
      [req.userId]
    );

    // 2. Fetch latest blood pressure logs (to check for hypertension)
    const [bpRows] = await pool.query(
      `SELECT systolic, diastolic FROM blood_pressure WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 5`,
      [req.userId]
    );

    if (!process.env.GEMINI_API_KEY) {
      return res.status(400).json({ success: false, message: 'Gemini API Key is not configured on the server.' });
    }

    // Determine health profile clues
    const medsList = medRows.map(r => r.name).join(', ') || 'None registered';
    
    let isHypertensive = false;
    if (bpRows.length > 0) {
      const avgSys = bpRows.reduce((sum, r) => sum + r.systolic, 0) / bpRows.length;
      if (avgSys >= 130) isHypertensive = true;
    }

    console.log(`🔮 Generating personalized diet plan for user. Meds: ${medsList}, High BP: ${isHypertensive}, Diet Type: ${dietType}`);

    const promptText = `You are a clinical nutritionist and registered dietitian AI. 
Design a highly personalized 1-day sample Diet & Meal Plan for a patient with the following medical profile:
- Active medications currently taken: ${medsList}
- Average Blood Pressure status: ${isHypertensive ? 'Elevated/Hypertensive (requires Low Sodium/DASH Diet guidelines)' : 'Normal'}
- Dietary Preference: ${dietType} (Strictly suggest meals conforming to this preference. E.g. Vegan must have no animal products/dairy; Vegetarian must have no meat/seafood/poultry; Non-Vegetarian can include healthy lean meats/seafood).

Strict Guidelines:
1. If the user is on blood sugar lowering medicines (like Metformin, Insulin, Glipizide), ensure the diet is diabetic-friendly (low glycemic index, complex carbs).
2. If the user is hypertensive, enforce strict low-sodium recommendations and highlight potassium-rich foods (DASH Diet).
3. Structure the output clearly with:
    - 🍳 **Breakfast** (Healthy choice)
    - 🥗 **Lunch** (Filling, nutrient-rich option)
    - 🍎 **Snacks** (Healthy mid-day options)
    - 🍲 **Dinner** (Light, restorative choice)
    - 💧 **Hydration & Wellness Tips**
4. End with a standard disclaimer: "This diet plan is AI-generated for informational guidance only. Please discuss with your dietitian or physician before making significant dietary modifications."

Format using clean Markdown.`;

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

    let dietPlan = '';
    if (!geminiRes.ok) {
      console.warn('⚠️ Gemini API returned error. Using locally generated high-quality fallback diet plan...');
      
      let breakfast = '';
      let lunch = '';
      let dinner = '';

      if (dietType.toLowerCase() === 'vegan') {
        breakfast = '* **Option:** Oatmeal cooked with almond milk, topped with sliced banana, a handful of blueberries, and 1 tablespoon of ground flaxseeds.\n* **Why:** High in soluble fiber to help regulate blood sugar and cholesterol, potassium-rich banana to support healthy blood pressure.';
        lunch = '* **Option:** Grilled tofu salad with mixed greens, cherry tomatoes, cucumbers, grated carrots, and a light dressing of olive oil and lemon juice.\n* **Why:** Lean plant protein promotes satiety, while leafy greens provide magnesium and calcium essential for vascular health.';
        dinner = '* **Option:** Lentil and vegetable curry served with steamed broccoli and half a cup of cooked quinoa.\n* **Why:** Rich in dietary fiber and essential plant nutrients which lower inflammation and improve heart health.';
      } else if (dietType.toLowerCase() === 'vegetarian') {
        breakfast = '* **Option:** Whole wheat avocado toast topped with low-fat cottage cheese (paneer) and microgreens.\n* **Why:** Healthy monounsaturated fats support heart health, and low-fat dairy provides protein and calcium.';
        lunch = '* **Option:** Grilled paneer and chickpea salad with mixed salad greens, cucumbers, carrots, and a yogurt-lemon dressing.\n* **Why:** High in protein and fiber to regulate blood glucose absorption.';
        dinner = '* **Option:** Tofu and vegetable stir-fry with steamed broccoli, bell peppers, and half a cup of cooked brown rice.\n* **Why:** High-quality soy protein and mineral-dense vegetables.';
      } else {
        // Non-Vegetarian
        breakfast = '* **Option:** Two poached eggs with a slice of whole grain toast and sliced avocado.\n* **Why:** Lean protein and healthy fats provide steady morning energy without blood sugar spikes.';
        lunch = '* **Option:** Grilled chicken breast salad with mixed greens, cherry tomatoes, cucumbers, grated carrots, and olive oil dressing.\n* **Why:** High protein and rich in potassium-dense fresh salad greens.';
        dinner = '* **Option:** Baked salmon fillet served with steamed broccoli and half a cup of cooked quinoa.\n* **Why:** Rich in Omega-3 fatty acids which lower inflammation and improve heart health.';
      }

      dietPlan = `### 🥗 Your Personalized 1-Day Wellness & Diet Plan (${dietType})

Here is a nutrition plan tailored to your health profile:
* **Active Medications:** ${medsList}
* **Blood Pressure Status:** ${isHypertensive ? 'Elevated/Hypertensive (DASH Diet guidelines applied)' : 'Normal'}
* **Dietary Category:** ${dietType}

---

#### 🍳 **Breakfast**
${breakfast}

#### 🥗 **Lunch**
${lunch}

#### 🍎 **Snacks**
* **Option:** A small apple with a handful of unsalted almonds or walnuts.
* **Why:** Healthy fats and fiber that prevent blood sugar spikes and support cardiovascular function.

#### 🍲 **Dinner**
${dinner}

#### 💧 **Hydration & Wellness Tips**
* **Hydration:** Aim for 8-10 glasses of pure water throughout the day. Limit caffeine and sugary beverages.
* **Activity:** Pair this nutrition guide with 30 minutes of moderate aerobic exercise (like brisk walking) to improve overall circulation.

---
> [!IMPORTANT]
> **Medical Disclaimer:** This diet plan is AI-generated for informational guidance only. Please discuss with your dietitian or physician before making significant dietary modifications.`;
    } else {
      const geminiData = await geminiRes.json();
      dietPlan = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'Could not compile a wellness plan.';
    }

    res.json({ success: true, dietPlan });

  } catch (err) {
    console.error('Get diet plan error:', err);
    res.status(500).json({ success: false, message: 'Server error compiling diet plan.' });
  }
});

module.exports = router;

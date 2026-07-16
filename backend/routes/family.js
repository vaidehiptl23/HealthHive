const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');

// GET all family members for logged in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM family_members WHERE user_id = ? ORDER BY created_at DESC`,
      [req.userId]
    );
    const [userRows] = await pool.query('SELECT subscription_plan FROM users WHERE id = ?', [req.userId]);
    const plan = userRows[0]?.subscription_plan || 'free';
    res.json({ success: true, data: rows, subscriptionPlan: plan });
  } catch (err) {
    console.error('Get family error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST to add family member with SUBSCRIPTION PAYWALL
router.post('/', auth, async (req, res) => {
  try {
    // 1. Fetch User's current subscription plan
    const [userRows] = await pool.query('SELECT subscription_plan FROM users WHERE id = ?', [req.userId]);
    const plan = userRows[0]?.subscription_plan || 'free';

    // 2. Fetch current family members count
    const [familyRows] = await pool.query('SELECT COUNT(*) as count FROM family_members WHERE user_id = ?', [req.userId]);
    const currentCount = familyRows[0].count;

    // 3. Apply Limits
    let limit = 1;
    if (plan === 'plus') limit = 5;
    if (plan === 'premium') limit = 999;

    if (currentCount >= limit) {
      return res.status(403).json({ 
        success: false, 
        message: `Plan limit reached. Upgrade to add more family members.`,
        requiresUpgrade: true
      });
    }

    const { first_name, middle_name, last_name, email, blood_group, gender, phone, dob, height, weight, address } = req.body;

    const [dbResult] = await pool.query(
      `INSERT INTO family_members (user_id, first_name, middle_name, last_name, email, blood_group, gender, phone, dob, height, weight, address)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.userId, first_name, middle_name || '', last_name, email || '', blood_group || '', gender || '', phone || '', dob || '', height || '', weight || '', address || '']
    );

    res.status(201).json({ success: true, message: 'Family member added', id: dbResult.insertId });

  } catch (err) {
    console.error('Add family error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// PUT to update family member emergency details
router.put('/:id/emergency', auth, async (req, res) => {
  try {
    const { emergency_contact_name, emergency_contact_phone, emergency_blood_group, allergies, existing_conditions } = req.body;
    
    // Ensure the family member belongs to the current user
    const [result] = await pool.query(
      `UPDATE family_members 
       SET emergency_contact_name = ?, emergency_contact_phone = ?, emergency_blood_group = ?, allergies = ?, existing_conditions = ? 
       WHERE id = ? AND user_id = ?`,
      [emergency_contact_name, emergency_contact_phone, emergency_blood_group, allergies, existing_conditions, req.params.id, req.userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Family member not found' });
    }

    res.json({ success: true, message: 'Family emergency details updated' });
  } catch (err) {
    console.error('Update family emergency error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
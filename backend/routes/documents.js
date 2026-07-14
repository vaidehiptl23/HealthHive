const express = require('express');
const router = require('express').Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');
const fs = require('fs');
const path = require('path');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

// Helper: upload buffer to Cloudinary
function uploadToCloudinary(buffer, options) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(options, (error, result) => {
      if (error) reject(error);
      else resolve(result);
    });
    streamifier.createReadStream(buffer).pipe(stream);
  });
}

// GET all documents for logged-in user
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, type, category, upload_for, note, file_url, cloudinary_id, file_size, mime_type, created_at
       FROM documents WHERE user_id = ? ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('Get documents error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST upload a document
router.post('/upload', auth, async (req, res) => {
  try {
    if (!req.files || !req.files.file) {
      return res.status(400).json({ success: false, message: 'No file provided' });
    }

    const file = req.files.file;
    const { name, type, category, upload_for, note } = req.body;

    if (!ALLOWED_TYPES.includes(file.mimetype)) {
      return res.status(400).json({ success: false, message: 'Only JPEG, PNG and PDF allowed' });
    }
    if (file.size > MAX_SIZE) {
      return res.status(400).json({ success: false, message: 'File too large (max 10MB)' });
    }

    // Upload to Cloudinary
    console.log('File received:', file.name, file.mimetype, file.size, 'data length:', file.data ? file.data.length : 'null');
    const resourceType = file.mimetype === 'application/pdf' ? 'raw' : 'image';
    const buffer = file.data;
    if (!buffer || buffer.length === 0) {
      console.error('Empty buffer!');
      return res.status(400).json({ success: false, message: 'File data is empty' });
    }

    // Build folder: healthhive/user_{id}/[familymembers/name/]/prescription|report|insurance[/category]
    let folder = `healthhive/user_${req.userId}`;
    if (upload_for && upload_for !== 'Myself') {
      const memberFolder = upload_for.replace(/[^a-zA-Z0-9-_]/g, '_');
      folder += `/familymembers/${memberFolder}`;
    }

    const typeFolder = (type || 'other').toLowerCase().replace(/\s+/g, '_');
    folder += `/${typeFolder}`;

    // If it's a Report and a category was provided, create a subfolder for it
    if (type === 'Report' && category) {
      const subCategory = category.replace(/[^a-zA-Z0-9-_]/g, '_');
      folder += `/${subCategory}`;
    }

    const baseName = file.name.includes('.') ? file.name.substring(0, file.name.lastIndexOf('.')) : file.name;
    const ext = file.name.includes('.') ? file.name.substring(file.name.lastIndexOf('.')) : '';
    const safeName = baseName.replace(/[^a-zA-Z0-9-_]/g, '_');
    
    // Cloudinary needs the extension in the public_id for 'raw' files like PDFs to serve them correctly.
    const publicId = resourceType === 'raw' ? `${safeName}${ext}` : safeName;

    console.log('Running Cloudinary upload and Gemini extraction in parallel...');
    const [cloudinaryResult, aiExtractedMedicines] = await Promise.all([
      uploadToCloudinary(buffer, {
        folder: folder,
        resource_type: resourceType,
        public_id: publicId,
        use_filename: true,
        unique_filename: true,
      }),
      (async () => {
        if (type === 'Prescription' && process.env.GEMINI_API_KEY) {
          try {
            console.log('🔮 Running Gemini AI Analysis in parallel...');
            const geminiRes = await fetch(
              `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  contents: [
                    {
                      parts: [
                        {
                          text: "Analyze this medical prescription image or document and extract all medicines listed. Return ONLY a valid JSON array of objects representing each medicine. Do not wrap in markdown code blocks or add any other text. Return exactly a JSON array. Each object MUST have these keys: name (string, name of medicine), dose (string, e.g. '500mg' or '1 tab'), meal (string, one of 'After Meal', 'With Meal', 'Empty Stomach', 'No Dependency'), morning (boolean), afternoon (boolean), night (boolean), morning_time (string, format '08:00'), afternoon_time (string, format '13:00'), night_time (string, format '20:00')."
                        },
                        {
                          inline_data: {
                            mime_type: file.mimetype,
                            data: buffer.toString('base64'),
                          }
                        }
                      ]
                    }
                  ],
                  generationConfig: {
                    responseMimeType: "application/json"
                  }
                })
              }
            );

            if (geminiRes.ok) {
              const geminiData = await geminiRes.json();
              const jsonText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
              if (jsonText) {
                const parsed = JSON.parse(jsonText.trim());
                console.log('✅ Parallel Gemini Extracted Medicines:', parsed);
                return parsed;
              }
            } else {
              console.error('Gemini API Error (Parallel):', geminiRes.status, await geminiRes.text());
            }
          } catch (e) {
            console.error('Gemini parallel error:', e.message);
          }
        }
        return [];
      })()
    ]);

    const [dbResult] = await pool.query(
      `INSERT INTO documents (user_id, name, type, category, upload_for, note, file_url, cloudinary_id, file_size, mime_type)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.userId,
        name || file.name,
        type || null,
        category || null,
        upload_for || null,
        note || null,
        cloudinaryResult.secure_url,
        cloudinaryResult.public_id,
        file.size,
        file.mimetype,
      ]
    );

    const [row] = await pool.query('SELECT * FROM documents WHERE id = ?', [dbResult.insertId]);
    console.log('Upload success, Cloudinary URL:', cloudinaryResult.secure_url);

    res.status(201).json({ 
      success: true, 
      data: row[0], 
      ai_extracted_medicines: aiExtractedMedicines 
    });
  } catch (err) {
    console.error('Upload document error:', JSON.stringify(err), err.message);
    res.status(500).json({ success: false, message: err.message || 'Server error' });
  }
});

// PUT rename a document
router.put('/:id/rename', auth, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name || name.trim() === '') {
      return res.status(400).json({ success: false, message: 'New name is required' });
    }

    const [result] = await pool.query(
      'UPDATE documents SET name = ? WHERE id = ? AND user_id = ?',
      [name.trim(), req.params.id, req.userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Document not found or unauthorized' });
    }

    res.json({ success: true, message: 'Document renamed successfully' });
  } catch (err) {
    console.error('Rename document error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// DELETE a document
router.delete('/:id', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM documents WHERE id = ? AND user_id = ?',
      [req.params.id, req.userId]
    );
    if (rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });

    const doc = rows[0];

    // Delete from Cloudinary
    if (doc.cloudinary_id) {
      const resourceType = doc.mime_type === 'application/pdf' ? 'raw' : 'image';
      await cloudinary.uploader.destroy(doc.cloudinary_id, { resource_type: resourceType });
    }

    await pool.query('DELETE FROM documents WHERE id = ? AND user_id = ?', [req.params.id, req.userId]);
    res.json({ success: true, message: 'Deleted' });
  } catch (err) {
    console.error('Delete document error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/documents/:id/analyze
router.post('/:id/analyze', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM documents WHERE id = ? AND user_id = ?',
      [req.params.id, req.userId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Document not found or unauthorized' });
    }

    const doc = rows[0];

    if (!process.env.GEMINI_API_KEY) {
      return res.status(400).json({ success: false, message: 'Gemini API Key is not configured on the server.' });
    }

    console.log(`🔮 Analyzing document id ${doc.id} (${doc.name}) using Gemini AI...`);

    let buffer;
    if (doc.file_url.startsWith('http://') || doc.file_url.startsWith('https://')) {
      const fileRes = await fetch(doc.file_url);
      if (!fileRes.ok) {
        throw new Error(`Failed to download file from Cloudinary: ${fileRes.statusText}`);
      }
      buffer = Buffer.from(await fileRes.arrayBuffer());
    } else {
      const filePath = path.join(__dirname, '..', doc.file_url);
      if (!fs.existsSync(filePath)) {
        throw new Error(`Local file not found at path: ${filePath}`);
      }
      buffer = fs.readFileSync(filePath);
    }

    const promptText = `You are HealthHive AI. Analyze this medical lab report or medical document image/PDF. 
Provide a clear, detailed, patient-friendly explanation of the findings.
1. Translate complex biomarkers or terms into simple, understandable language.
2. Clearly list any values that are high, low, or out of the normal range.
3. Suggest simple wellness, dietary, or lifestyle steps based on these findings.
4. End with a strong medical disclaimer: "This AI analysis is for informational purposes only. Please consult your physician or healthcare provider to interpret these results and prescribe treatment."
Format the response using clean Markdown with clear headings and bullet points.`;

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: promptText },
                {
                  inline_data: {
                    mime_type: doc.mime_type || 'application/pdf',
                    data: buffer.toString('base64'),
                  }
                }
              ]
            }
          ]
        })
      }
    );

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      console.error('Gemini API Error:', geminiRes.status, errText);
      return res.status(502).json({ success: false, message: 'Gemini AI service error' });
    }

    const geminiData = await geminiRes.json();
    const analysis = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || 'Could not parse analysis results.';

    res.json({ success: true, analysis });

  } catch (err) {
    console.error('Analyze document error:', err);
    res.status(500).json({ success: false, message: err.message || 'Server error' });
  }
});

module.exports = router;

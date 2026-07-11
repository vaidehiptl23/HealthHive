const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pool = require('../config/database');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

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

    console.log('Uploading to Cloudinary, resource_type:', resourceType, 'folder:', folder);
    const result = await uploadToCloudinary(buffer, {
      folder: folder,
      resource_type: resourceType,
      public_id: publicId,
      use_filename: true,
      unique_filename: true,
    });

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
        result.secure_url,
        result.public_id,
        file.size,
        file.mimetype,
      ]
    );

    const [row] = await pool.query('SELECT * FROM documents WHERE id = ?', [dbResult.insertId]);
    console.log('Upload success, Cloudinary URL:', result.secure_url);
    res.status(201).json({ success: true, data: row[0] });
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

module.exports = router;

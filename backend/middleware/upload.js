const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const uploadMiddleware = (req, res, next) => {
  if (!req.files || Object.keys(req.files).length === 0) {
    return next();
  }

  const file = req.files.file;
  const maxSize = process.env.MAX_FILE_SIZE || 5242880; // 5MB default
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  
  // Check file size
  if (file.size > maxSize) {
    return res.status(400).json({
      success: false,
      message: `File too large. Maximum size is ${maxSize / 1024 / 1024}MB`
    });
  }
  
  // Check file type
  if (!allowedTypes.includes(file.mimetype)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid file type. Only JPEG, PNG, and PDF files are allowed'
    });
  }
  
  // Generate unique filename
  const fileExt = path.extname(file.name);
  const fileName = `${Date.now()}-${Math.round(Math.random() * 1E9)}${fileExt}`;
  const filePath = path.join(uploadDir, fileName);
  
  // Move file to uploads directory
  file.mv(filePath, (err) => {
    if (err) {
      console.error('File upload error:', err);
      return res.status(500).json({
        success: false,
        message: 'Error uploading file'
      });
    }
    
    // Add file info to request
    req.fileInfo = {
      name: fileName,
      originalName: file.name,
      path: `/uploads/${fileName}`,
      size: file.size,
      mimeType: file.mimetype,
      extension: fileExt
    };
    
    next();
  });
};

module.exports = uploadMiddleware;
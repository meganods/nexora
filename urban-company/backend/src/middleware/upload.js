const multer = require('multer');

// Configure in-memory upload buffering to simplify piping straight to Google Cloud Storage
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf') {
    cb(null, true);
  } else {
    cb(new Error('Invalid File Type: Only images and PDF files are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB Limit
  },
  fileFilter: fileFilter
});

module.exports = upload;

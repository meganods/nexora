const nodemailer = require('nodemailer');
const dotenv = require('dotenv');

dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  tls: {
    rejectUnauthorized: false
  }
});

// Verify mail configuration connection pool
transporter.verify((error, success) => {
  if (error) {
    console.error('Mail SMTP connection test failed:', error.message);
  } else {
    console.log('Mail SMTP server connection ready for dispatch.');
  }
});

module.exports = transporter;

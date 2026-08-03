const express = require('express');
const { body } = require('express-validator');
const { register, login, refreshToken, forgotPassword, verifyResetOtp, resetPassword } = require('../controllers/authController');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

router.post(
  '/register',
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('name').notEmpty().withMessage('Name field is required'),
    validateFields
  ],
  register
);

router.post(
  '/login',
  [
    body('idToken').notEmpty().withMessage('Firebase idToken is required'),
    validateFields
  ],
  login
);

router.post(
  '/refresh',
  [
    body('token').notEmpty().withMessage('Refresh token is required'),
    validateFields
  ],
  refreshToken
);

router.post(
  '/forgot-password',
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    validateFields
  ],
  forgotPassword
);

router.post(
  '/verify-reset-otp',
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be exactly 6 digits'),
    validateFields
  ],
  verifyResetOtp
);

router.post(
  '/reset-password',
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be exactly 6 digits'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    validateFields
  ],
  resetPassword
);

module.exports = router;

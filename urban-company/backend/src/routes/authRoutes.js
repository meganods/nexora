const express = require('express');
const { body } = require('express-validator');
const rateLimit = require('express-rate-limit');
const {
  register,
  login,
  refreshToken,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
  sendLoginOtp,
  verifyLoginOtp,
  sendRegisterOtp,
  verifyRegisterOtp,
} = require('../controllers/authController');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

// ─── Rate Limiters ────────────────────────────────────────────────────────────

// Strict limiter for OTP send: max 5 requests per 15 minutes per IP
const otpSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    success: false,
    message: 'Too many OTP requests. Please wait 15 minutes before trying again.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict limiter for OTP verify: max 10 requests per 15 minutes per IP
const otpVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    success: false,
    message: 'Too many verification attempts. Please wait 15 minutes before trying again.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// ─── Routes ───────────────────────────────────────────────────────────────────

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

// ─── Login MFA — Send OTP to email ───────────────────────────────────────────
// Requires valid Firebase ID Token (credentials already verified by Firebase Auth on client)
router.post(
  '/send-login-otp',
  otpSendLimiter,
  [
    body('idToken').notEmpty().withMessage('Firebase idToken is required'),
    validateFields
  ],
  sendLoginOtp
);

// ─── Login MFA — Verify OTP entered by user ───────────────────────────────────
router.post(
  '/verify-login-otp',
  otpVerifyLimiter,
  [
    body('idToken').notEmpty().withMessage('Firebase idToken is required'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .withMessage('OTP must be exactly 6 digits')
      .matches(/^\d{6}$/)
      .withMessage('OTP must contain only digits'),
    validateFields
  ],
  verifyLoginOtp
);

// ─── Vendor Registration OTP — Send code to email ───────────────────────────
router.post(
  '/send-register-otp',
  otpSendLimiter,
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    body('name').optional().isString(),
    validateFields
  ],
  sendRegisterOtp
);

// ─── Vendor Registration OTP — Verify code entered by user ───────────────────
router.post(
  '/verify-register-otp',
  otpVerifyLimiter,
  [
    body('email').isEmail().withMessage('Enter a valid email address'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .withMessage('OTP must be exactly 6 digits')
      .matches(/^\d{6}$/)
      .withMessage('OTP must contain only digits'),
    validateFields
  ],
  verifyRegisterOtp
);

module.exports = router;

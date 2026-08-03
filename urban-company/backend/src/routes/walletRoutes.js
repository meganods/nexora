const express = require('express');
const { body } = require('express-validator');
const { getWalletDetails, creditReferralReward } = require('../controllers/walletController');
const authMiddleware = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

router.get('/', authMiddleware, getWalletDetails);

// Only admins can credit wallet rewards manually
router.post(
  '/reward',
  authMiddleware,
  adminAuth,
  [
    body('userId').notEmpty().withMessage('userId is required'),
    body('rewardAmount').isNumeric().withMessage('rewardAmount must be numeric'),
    validateFields
  ],
  creditReferralReward
);

module.exports = router;

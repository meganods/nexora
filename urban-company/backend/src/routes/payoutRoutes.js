const express = require('express');
const authMiddleware = require('../middleware/auth');
const {
  requestWithdrawal,
  getVendorWithdrawals,
  getAdminPendingWithdrawals,
  approveWithdrawal,
  rejectWithdrawal
} = require('../controllers/payoutController');

const router = express.Router();

router.use(authMiddleware);

// Vendor endpoints
router.post('/request', requestWithdrawal);
router.get('/vendor-history', getVendorWithdrawals);

// Admin endpoints
router.get('/admin-pending', getAdminPendingWithdrawals);
router.post('/approve', approveWithdrawal);
router.post('/reject', rejectWithdrawal);

module.exports = router;

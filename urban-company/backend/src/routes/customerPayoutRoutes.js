const express = require('express');
const authMiddleware = require('../middleware/auth');
const {
  requestCustomerWithdrawal,
  getCustomerWithdrawals,
  approveCustomerWithdrawal,
  rejectCustomerWithdrawal
} = require('../controllers/customerPayoutController');

const router = express.Router();

router.use(authMiddleware);

// Customer endpoints
router.post('/request', requestCustomerWithdrawal);
router.get('/history', getCustomerWithdrawals);

// Admin endpoints
router.post('/approve', approveCustomerWithdrawal);
router.post('/reject', rejectCustomerWithdrawal);

module.exports = router;

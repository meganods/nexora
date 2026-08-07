const express = require('express');
const { body } = require('express-validator');
const { 
  createOrder, 
  verifyPaymentSignature, 
  handleWebhook,
  createCashfreeOrder,
  verifyCashfreePayment
} = require('../controllers/paymentController');
const authMiddleware = require('../middleware/auth');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

// Webhook route is public (Razorpay server calls it)
router.post('/webhook', handleWebhook);

// Secured endpoints
router.post(
  '/order',
  authMiddleware,
  [
    body('amount').isNumeric().withMessage('amount is required'),
    body('bookingId').notEmpty().withMessage('bookingId is required'),
    validateFields
  ],
  createOrder
);

router.post(
  '/verify',
  authMiddleware,
  [
    body('razorpay_order_id').notEmpty().withMessage('razorpay_order_id is required'),
    body('razorpay_payment_id').notEmpty().withMessage('razorpay_payment_id is required'),
    body('razorpay_signature').notEmpty().withMessage('razorpay_signature is required'),
    body('bookingId').notEmpty().withMessage('bookingId is required'),
    validateFields
  ],
  verifyPaymentSignature
);

// Cashfree Specific Endpoints
router.post(
  '/cashfree/order',
  authMiddleware,
  [
    body('amount').isNumeric().withMessage('amount is required'),
    validateFields
  ],
  createCashfreeOrder
);

router.post(
  '/cashfree/verify',
  authMiddleware,
  [
    body('orderId').notEmpty().withMessage('orderId is required'),
    validateFields
  ],
  verifyCashfreePayment
);

module.exports = router;


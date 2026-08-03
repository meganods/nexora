const express = require('express');
const { body } = require('express-validator');
const { getSystemStats, approveVendor, rejectVendor } = require('../controllers/adminController');
const authMiddleware = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);
router.use(adminAuth);

router.get('/stats', getSystemStats);

router.post(
  '/vendors/approve',
  [
    body('vendorId').notEmpty().withMessage('vendorId is required'),
    validateFields
  ],
  approveVendor
);

router.post(
  '/vendors/reject',
  [
    body('vendorId').notEmpty().withMessage('vendorId is required'),
    body('reason').notEmpty().withMessage('rejection reason is required'),
    validateFields
  ],
  rejectVendor
);

module.exports = router;

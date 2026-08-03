const express = require('express');
const { body } = require('express-validator');
const { createBooking, getBookingById, updateBookingStatus, getTimeline } = require('../controllers/bookingController');
const authMiddleware = require('../middleware/auth');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.post(
  '/',
  [
    body('serviceId').notEmpty().withMessage('serviceId is required'),
    body('subServiceId').notEmpty().withMessage('subServiceId is required'),
    body('address').notEmpty().withMessage('address is required'),
    body('scheduledDate').notEmpty().withMessage('scheduledDate is required'),
    body('scheduledTime').notEmpty().withMessage('scheduledTime is required'),
    body('totalAmount').isNumeric().withMessage('totalAmount must be a number'),
    validateFields
  ],
  createBooking
);

router.get('/:id', getBookingById);
router.get('/:id/timeline', getTimeline);
router.put('/:id/status', updateBookingStatus);

module.exports = router;

const express = require('express');
const { body } = require('express-validator');
const { createSupportTicket, getMyTickets } = require('../controllers/supportController');
const authMiddleware = require('../middleware/auth');
const { validateFields } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.post(
  '/',
  [
    body('title').notEmpty().withMessage('title is required'),
    body('description').notEmpty().withMessage('description is required'),
    body('category').notEmpty().withMessage('category is required'),
    validateFields
  ],
  createSupportTicket
);

router.get('/', getMyTickets);

module.exports = router;

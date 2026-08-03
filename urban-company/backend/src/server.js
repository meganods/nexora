const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');

// Import Configs to trigger initialization validation logs
require('./config/firebase');
require('./config/mail');
require('./config/razorpay');

// Import Routes
const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const walletRoutes = require('./routes/walletRoutes');
const supportRoutes = require('./routes/supportRoutes');
const adminRoutes = require('./routes/adminRoutes');

// Import Middleware
const errorHandler = require('./middleware/errorHandler');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable Trust Proxy for Rate Limiting behind load balancers (Render, Railway, GCR)
app.set('trust proxy', 1);

// Security Middlewares
app.use(helmet());
app.use(cors({
  origin: '*', // Enable open API CORS rules (production setups should configure specific origin limits)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Performance Gzip Compression
app.use(compression());

// Logger
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Parse payload bodies
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Global Rate Limiter: Max 200 requests per 15 minutes per IP
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again after 15 minutes.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(globalLimiter);

// Health Check Endpoint
app.get('/health', (req, res) => {
  return res.status(200).json({
    success: true,
    status: 'UP',
    timestamp: new Date(),
    uptime: process.uptime()
  });
});

// Register Api Routers
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/wallet', walletRoutes);
app.use('/api/v1/support', supportRoutes);
app.use('/api/v1/admin', adminRoutes);

// Fallback Not Found Endpoint
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `API Route Not Found: ${req.originalUrl}`
  });
});

// Global Error Handler Boundary Middleware (MUST be registered last)
app.use(errorHandler);

// Start HTTP Server
const server = app.listen(PORT, () => {
  console.log(`Nexora Production Backend executing on port ${PORT} in ${process.env.NODE_ENV} mode.`);
});

module.exports = server;

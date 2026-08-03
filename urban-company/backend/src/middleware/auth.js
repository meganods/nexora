const jwt = require('jsonwebtoken');
const { auth: firebaseAuth } = require('../config/firebase');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Access Denied: No Token Provided' });
    }

    const token = authHeader.split(' ')[1];

    // 1. Try custom JWT authentication first
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'b7c62d08a543fbe0a18347fcd611986427d14285b7364654ad8f9024f2b1c8f');
      req.user = decoded;
      return next();
    } catch (jwtError) {
      // 2. Fallback: Verify if it is a Firebase ID Token
      try {
        const decodedFirebaseUser = await firebaseAuth.verifyIdToken(token);
        req.user = {
          uid: decodedFirebaseUser.uid,
          email: decodedFirebaseUser.email || '',
          role: decodedFirebaseUser.role || 'customer'
        };
        return next();
      } catch (firebaseError) {
        return res.status(401).json({ success: false, message: 'Authentication Failed: Invalid or Expired Token' });
      }
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Authentication Process Error', error: error.message });
  }
};

module.exports = authMiddleware;

const jwt = require('jsonwebtoken');
const { auth: firebaseAuth, db } = require('../config/firebase');

const generateTokens = (user) => {
  const payload = { uid: user.uid, email: user.email, role: user.role || 'customer' };
  const accessToken = jwt.sign(
    payload,
    process.env.JWT_SECRET || 'b7c62d08a543fbe0a18347fcd611986427d14285b7364654ad8f9024f2b1c8f',
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

  const refreshToken = jwt.sign(
    payload,
    process.env.JWT_REFRESH_SECRET || 'e79c2980183ac2fb781b2ef109cb34bda2471603597c23946ac7900b14c33df',
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
  );

  return { accessToken, refreshToken };
};

const register = async (req, res) => {
  try {
    const { email, password, name, role } = req.body;
    
    // Default fallback to customer
    const userRole = role === 'admin' || role === 'vendor' ? role : 'customer';

    // 1. Create Firebase User
    const firebaseUser = await firebaseAuth.createUser({
      email,
      password,
      displayName: name,
    });

    // 2. Set Custom User Claims on Firebase Auth
    await firebaseAuth.setCustomUserClaims(firebaseUser.uid, { role: userRole });

    // 3. Save User Profile in Firestore
    const userDocRef = db.collection('users').doc(firebaseUser.uid);
    await userDocRef.set({
      uid: firebaseUser.uid,
      name,
      email,
      role: userRole,
      createdAt: new Date(),
      hasCompletedAddressSetup: false,
    });

    const tokens = generateTokens({ uid: firebaseUser.uid, email, role: userRole });

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: { uid: firebaseUser.uid, name, email, role: userRole },
      ...tokens
    });
  } catch (error) {
    return res.status(400).json({ success: false, message: 'Registration Failed', error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { idToken } = req.body;

    // Verify incoming Firebase Token
    const decodedToken = await firebaseAuth.verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email || '';

    // Verify profile exists in Firestore
    const userDoc = await db.collection('users').doc(uid).get();
    let role = decodedToken.role || 'customer';
    let name = decodedToken.name || '';

    if (!userDoc.exists) {
      // Upsert missing profiles
      await db.collection('users').doc(uid).set({
        uid,
        email,
        name,
        role,
        createdAt: new Date(),
        hasCompletedAddressSetup: false,
      });
    } else {
      role = userDoc.data().role || role;
      name = userDoc.data().name || name;
    }

    const tokens = generateTokens({ uid, email, role });

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      user: { uid, email, name, role },
      ...tokens
    });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Authentication Failed', error: error.message });
  }
};

const refreshToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET || 'e79c2980183ac2fb781b2ef109cb34bda2471603597c23946ac7900b14c33df');
    const tokens = generateTokens({ uid: decoded.uid, email: decoded.email, role: decoded.role });

    return res.status(200).json({
      success: true,
      ...tokens
    });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or Expired Refresh Token' });
  }
};

module.exports = {
  register,
  login,
  refreshToken
};

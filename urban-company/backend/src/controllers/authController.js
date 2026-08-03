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

const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    // Check if email exists in users collection
    const userQuery = await db.collection('users')
      .where('email', '==', email.trim().toLowerCase())
      .limit(1)
      .get();

    if (userQuery.empty) {
      return res.status(404).json({ success: false, message: 'Email address not registered' });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiry

    // Save token record in Firestore
    await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).set({
      email: email.trim().toLowerCase(),
      otp,
      expiresAt,
      verified: false,
      createdAt: new Date()
    });

    // Send Verification OTP Email via emailService
    const { sendTemplateMail } = require('../services/emailService');
    await sendTemplateMail(
      email.trim().toLowerCase(), 
      'Reset Your Nexora Password', 
      'otp', 
      { OTP_CODE: otp }
    );

    return res.status(200).json({ success: true, message: 'Verification OTP sent to your email' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to process password reset request', error: error.message });
  }
};

const verifyResetOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const tokenDoc = await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).get();
    if (!tokenDoc.exists) {
      return res.status(400).json({ success: false, message: 'Verification session expired or invalid' });
    }

    const data = tokenDoc.data();
    if (data.otp !== otp) {
      return res.status(400).json({ success: false, message: 'Invalid verification OTP code' });
    }

    if (new Date() > data.expiresAt.toDate()) {
      return res.status(400).json({ success: false, message: 'Verification OTP has expired' });
    }

    // Mark as verified
    await tokenDoc.ref.update({ verified: true });

    return res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Verification failed', error: error.message });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { email, otp, password } = req.body;

    const tokenDoc = await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).get();
    if (!tokenDoc.exists) {
      return res.status(400).json({ success: false, message: 'Session invalid' });
    }

    const data = tokenDoc.data();
    if (!data.verified || data.otp !== otp) {
      return res.status(400).json({ success: false, message: 'OTP verification required before reset' });
    }

    // Find the user's Firebase UID
    const userQuery = await db.collection('users')
      .where('email', '==', email.trim().toLowerCase())
      .limit(1)
      .get();

    if (userQuery.empty) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    const uid = userQuery.docs[0].id;

    // Update password in Firebase Auth
    await firebaseAuth.updateUser(uid, { password });

    // Invalidate/delete the used token
    await tokenDoc.ref.delete();

    return res.status(200).json({ success: true, message: 'Password reset successful' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to reset password', error: error.message });
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  forgotPassword,
  verifyResetOtp,
  resetPassword
};

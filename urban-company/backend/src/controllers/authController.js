const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { auth: firebaseAuth, db } = require('../config/firebase');
const { FieldValue } = require('firebase-admin/firestore');

// ─── Token Generation ─────────────────────────────────────────────────────────
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

// ─── Helper: Cryptographically secure 6-digit OTP ────────────────────────────
const generateSecureOtp = () => String(crypto.randomInt(100000, 999999));

// ─── Helper: Unique login session identifier ──────────────────────────────────
const generateSessionId = () => crypto.randomUUID();

// ─── Helper: Extract device metadata from request ────────────────────────────
const extractDeviceMeta = (req) => {
  const userAgent = req.headers['user-agent'] || 'unknown';
  const ipAddress =
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
    req.headers['x-real-ip'] ||
    req.socket?.remoteAddress ||
    'unknown';

  // Simple UA-based platform detection
  let platform = 'Unknown';
  if (/android/i.test(userAgent)) platform = 'Android';
  else if (/iphone|ipad|ipod/i.test(userAgent)) platform = 'iOS';
  else if (/windows/i.test(userAgent)) platform = 'Windows';
  else if (/mac/i.test(userAgent)) platform = 'macOS';
  else if (/linux/i.test(userAgent)) platform = 'Linux';

  // Rough device name extraction (first significant token from UA)
  let deviceName = 'Unknown Device';
  const uaMatch = userAgent.match(/\(([^)]+)\)/);
  if (uaMatch) {
    deviceName = uaMatch[1].split(';')[0].trim().substring(0, 60);
  }

  return { ipAddress, platform, deviceName, userAgent: userAgent.substring(0, 200) };
};

// ─── Helper: Write to audit log (non-blocking) ────────────────────────────────
// Canonical events: OTP_SENT | OTP_RESENT | OTP_VERIFIED | OTP_EXPIRED |
//                   OTP_WRONG | OTP_BLOCKED | RESEND_BLOCKED | LOGIN_SUCCESS |
//                   LOGIN_FAILED | ACCOUNT_LOCKED
const writeAuditLog = async (uid, email, action, meta = {}) => {
  try {
    await db.collection('otp_audit_log').add({
      uid,
      email,
      action,
      ...meta,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Non-blocking — audit failure must never interrupt the auth flow
  }
};

// ─── register ────────────────────────────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { email, password, name, role } = req.body;
    const userRole = role === 'admin' || role === 'vendor' ? role : 'customer';

    const firebaseUser = await firebaseAuth.createUser({ email, password, displayName: name });
    await firebaseAuth.setCustomUserClaims(firebaseUser.uid, { role: userRole });

    await db.collection('users').doc(firebaseUser.uid).set({
      uid: firebaseUser.uid,
      name,
      email,
      role: userRole,
      createdAt: FieldValue.serverTimestamp(),
      hasCompletedAddressSetup: false,
    });

    const tokens = generateTokens({ uid: firebaseUser.uid, email, role: userRole });
    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: { uid: firebaseUser.uid, name, email, role: userRole },
      ...tokens,
    });
  } catch (error) {
    return res.status(400).json({ success: false, message: 'Registration Failed', error: error.message });
  }
};

// ─── login ───────────────────────────────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { idToken } = req.body;
    const decodedToken = await firebaseAuth.verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email || '';

    const userDoc = await db.collection('users').doc(uid).get();
    let role = decodedToken.role || 'customer';
    let name = decodedToken.name || '';

    if (!userDoc.exists) {
      await db.collection('users').doc(uid).set({
        uid, email, name, role,
        createdAt: FieldValue.serverTimestamp(),
        hasCompletedAddressSetup: false,
      });
    } else {
      role = userDoc.data().role || role;
      name = userDoc.data().name || name;
    }

    const tokens = generateTokens({ uid, email, role });
    return res.status(200).json({ success: true, message: 'Login successful', user: { uid, email, name, role }, ...tokens });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Authentication Failed', error: error.message });
  }
};

// ─── refreshToken ─────────────────────────────────────────────────────────────
const refreshToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ success: false, message: 'Refresh token is required' });

    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET || 'e79c2980183ac2fb781b2ef109cb34bda2471603597c23946ac7900b14c33df');
    const tokens = generateTokens({ uid: decoded.uid, email: decoded.email, role: decoded.role });
    return res.status(200).json({ success: true, ...tokens });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or Expired Refresh Token' });
  }
};

// ─── forgotPassword ───────────────────────────────────────────────────────────
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const userQuery = await db.collection('users').where('email', '==', email.trim().toLowerCase()).limit(1).get();
    if (userQuery.empty) return res.status(404).json({ success: false, message: 'Email address not registered' });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).set({
      email: email.trim().toLowerCase(), otp, expiresAt, verified: false, createdAt: new Date(),
    });

    const { sendTemplateMail } = require('../services/emailService');
    await sendTemplateMail(email.trim().toLowerCase(), 'Reset Your Nexora Password', 'otp', { OTP_CODE: otp });
    return res.status(200).json({ success: true, message: 'Verification OTP sent to your email' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to process password reset request', error: error.message });
  }
};

// ─── verifyResetOtp ───────────────────────────────────────────────────────────
const verifyResetOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const tokenDoc = await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).get();
    if (!tokenDoc.exists) return res.status(400).json({ success: false, message: 'Verification session expired or invalid' });

    const data = tokenDoc.data();
    if (data.otp !== otp) return res.status(400).json({ success: false, message: 'Invalid verification OTP code' });
    if (new Date() > data.expiresAt.toDate()) return res.status(400).json({ success: false, message: 'Verification OTP has expired' });

    await tokenDoc.ref.update({ verified: true });
    return res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Verification failed', error: error.message });
  }
};

// ─── resetPassword ────────────────────────────────────────────────────────────
const resetPassword = async (req, res) => {
  try {
    const { email, otp, password } = req.body;
    const tokenDoc = await db.collection('password_reset_tokens').doc(email.trim().toLowerCase()).get();
    if (!tokenDoc.exists) return res.status(400).json({ success: false, message: 'Session invalid' });

    const data = tokenDoc.data();
    if (!data.verified || data.otp !== otp) return res.status(400).json({ success: false, message: 'OTP verification required before reset' });

    const userQuery = await db.collection('users').where('email', '==', email.trim().toLowerCase()).limit(1).get();
    if (userQuery.empty) return res.status(404).json({ success: false, message: 'User profile not found' });

    await firebaseAuth.updateUser(userQuery.docs[0].id, { password });
    await tokenDoc.ref.delete();
    return res.status(200).json({ success: true, message: 'Password reset successful' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to reset password', error: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/v1/auth/send-login-otp
// ─────────────────────────────────────────────────────────────────────────────
// Improvements applied:
//  ✅ Invalidates any previous OTP immediately (one active OTP at a time)
//  ✅ Generates a new loginSessionId for full traceability
//  ✅ Captures device/IP/UA metadata and stores it in otp_verifications
//  ✅ Emits OTP_SENT / OTP_RESENT / RESEND_BLOCKED audit events
//  ✅ Max 3 resends per 10-minute window (then ACCOUNT_LOCKED event)
// ═══════════════════════════════════════════════════════════════════════════════
const sendLoginOtp = async (req, res) => {
  try {
    const { idToken } = req.body;
    const device = extractDeviceMeta(req);

    // 1. Verify Firebase ID Token
    let decodedToken;
    try {
      decodedToken = await firebaseAuth.verifyIdToken(idToken);
    } catch (_) {
      return res.status(401).json({ success: false, message: 'Invalid or expired authentication token.' });
    }

    const uid = decodedToken.uid;
    const email = decodedToken.email || '';
    const name = decodedToken.name || email.split('@')[0] || 'User';

    // 2. Resend-limit guard (max 3 per 10-minute window)
    const otpRef = db.collection('otp_verifications').doc(uid);
    const otpDoc = await otpRef.get();
    const MAX_RESENDS = 3;
    const WINDOW_MS = 10 * 60 * 1000;

    let isResend = false;
    let prevResendCount = 0;
    let sessionCreatedAt = new Date();

    if (otpDoc.exists) {
      const existing = otpDoc.data();
      prevResendCount = existing.resendCount || 0;
      sessionCreatedAt = existing.sessionCreatedAt ? existing.sessionCreatedAt.toDate() : new Date();
      const withinWindow = (Date.now() - sessionCreatedAt.getTime()) < WINDOW_MS;

      if (prevResendCount >= MAX_RESENDS && withinWindow) {
        await writeAuditLog(uid, email, 'ACCOUNT_LOCKED', {
          reason: 'MAX_RESEND_LIMIT',
          resendCount: prevResendCount,
          ...device,
        });
        return res.status(429).json({
          success: false,
          message: `Account temporarily locked. Maximum resend limit (${MAX_RESENDS}) reached. Please wait 10 minutes.`,
        });
      }

      // Window expired — reset resend counter
      if (!withinWindow) {
        prevResendCount = 0;
        sessionCreatedAt = new Date();
      }
      isResend = true;
    }

    // 3. Generate OTP, hash with bcrypt, create new loginSessionId
    const otp = generateSecureOtp();
    const otpHash = await bcrypt.hash(otp, 10);
    const loginSessionId = generateSessionId();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    const newResendCount = isResend ? prevResendCount + 1 : 1;

    // 4. Atomically overwrite otp_verifications — invalidates any previous OTP
    await otpRef.set({
      uid,
      email,
      otpHash,                          // hashed; plaintext never stored
      expiresAt,
      attempts: 0,
      resendCount: newResendCount,
      verified: false,
      loginSessionId,                   // unique per attempt for traceability
      sessionCreatedAt: isResend ? sessionCreatedAt : FieldValue.serverTimestamp(),
      // ── Device & IP metadata ──────────────────────────────────────────────
      ipAddress: device.ipAddress,
      platform: device.platform,
      deviceName: device.deviceName,
      userAgent: device.userAgent,
      loginTime: FieldValue.serverTimestamp(),
    });

    // 5. Send OTP via Nodemailer
    const { sendTemplateMail } = require('../services/emailService');
    await sendTemplateMail(email, 'Nexora Login Verification Code', 'login_otp', {
      USER_NAME: name,
      OTP_CODE: otp,
    });

    // 6. Write audit log
    await writeAuditLog(uid, email, isResend ? 'OTP_RESENT' : 'OTP_SENT', {
      loginSessionId,
      expiresAt,
      resendCount: newResendCount,
      ...device,
    });

    return res.status(200).json({
      success: true,
      message: 'Login verification code sent to your registered email address.',
      email: email.replace(/(.{2})(.*)(@.*)/, '$1****$3'),
    });
  } catch (error) {
    console.error('sendLoginOtp error:', error.message);
    return res.status(500).json({ success: false, message: 'Failed to send verification code. Please try again.', error: error.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/v1/auth/verify-login-otp
// ─────────────────────────────────────────────────────────────────────────────
// Improvements applied:
//  ✅ Firestore transaction — atomic update of verified/otpHash/attempts/expiresAt
//  ✅ Prevents race conditions from simultaneous verification requests
//  ✅ Full audit event set on every path (OTP_VERIFIED, OTP_EXPIRED, OTP_BLOCKED, etc.)
//  ✅ LOGIN_SUCCESS event with device/IP details
//  ✅ Device metadata captured and stored in audit log
// ═══════════════════════════════════════════════════════════════════════════════
const verifyLoginOtp = async (req, res) => {
  try {
    const { idToken, otp } = req.body;
    const device = extractDeviceMeta(req);

    // 1. Verify Firebase ID Token
    let decodedToken;
    try {
      decodedToken = await firebaseAuth.verifyIdToken(idToken);
    } catch (_) {
      return res.status(401).json({ success: false, message: 'Invalid or expired authentication token.' });
    }

    const uid = decodedToken.uid;
    const email = decodedToken.email || '';
    const MAX_ATTEMPTS = 5;
    const otpRef = db.collection('otp_verifications').doc(uid);

    // 2. Run Firestore transaction for atomic OTP verification
    let transactionResult;

    try {
      transactionResult = await db.runTransaction(async (transaction) => {
        const otpDoc = await transaction.get(otpRef);

        // ── Guard: session must exist ─────────────────────────────────────────
        if (!otpDoc.exists) {
          return { status: 'NO_SESSION' };
        }

        const data = otpDoc.data();
        const loginSessionId = data.loginSessionId || null;

        // ── Guard: already verified (replay protection) ───────────────────────
        if (data.verified === true) {
          return { status: 'ALREADY_VERIFIED', loginSessionId };
        }

        // ── Guard: too many attempts — lock ───────────────────────────────────
        if (data.attempts >= MAX_ATTEMPTS) {
          return { status: 'BLOCKED', attempts: data.attempts, loginSessionId };
        }

        // ── Guard: expired ─────────────────────────────────────────────────────
        const expiresAt = data.expiresAt ? data.expiresAt.toDate() : new Date(0);
        if (Date.now() > expiresAt.getTime()) {
          // Clear stale OTP inside the transaction
          transaction.update(otpRef, {
            otpHash: null,
            expiresAt: null,
            attempts: 0,
          });
          return { status: 'EXPIRED', loginSessionId };
        }

        // ── Check OTP hash — bcrypt compare must happen inside the transaction
        //    (async ops are allowed in Firestore transactions in Node.js SDK)
        const isMatch = await bcrypt.compare(otp, data.otpHash || '');

        if (!isMatch) {
          const newAttempts = data.attempts + 1;
          transaction.update(otpRef, { attempts: newAttempts });
          const remaining = MAX_ATTEMPTS - newAttempts;
          return { status: 'WRONG_OTP', newAttempts, remaining, loginSessionId };
        }

        // ── ✅ OTP correct — atomically clear all sensitive fields ────────────
        transaction.update(otpRef, {
          verified: true,
          verifiedAt: FieldValue.serverTimestamp(),
          otpHash: null,    // wipe hash immediately after use
          expiresAt: null,  // invalidate expiry
          attempts: 0,      // reset counter
        });

        return { status: 'SUCCESS', loginSessionId };
      });
    } catch (txError) {
      console.error('verifyLoginOtp transaction error:', txError.message);
      return res.status(500).json({ success: false, message: 'Verification failed. Please try again.' });
    }

    // 3. Handle transaction outcomes
    const { status, loginSessionId, attempts, remaining, newAttempts } = transactionResult;
    const auditMeta = { loginSessionId, ...device };

    if (status === 'NO_SESSION') {
      await writeAuditLog(uid, email, 'LOGIN_FAILED', { reason: 'NO_SESSION', ...auditMeta });
      return res.status(400).json({ success: false, message: 'No active verification session. Please request a new code.' });
    }

    if (status === 'ALREADY_VERIFIED') {
      await writeAuditLog(uid, email, 'LOGIN_FAILED', { reason: 'REPLAY_ATTEMPT', ...auditMeta });
      return res.status(400).json({ success: false, message: 'This code has already been used. Please request a new one.' });
    }

    if (status === 'BLOCKED') {
      await writeAuditLog(uid, email, 'OTP_BLOCKED', { attempts, ...auditMeta });
      return res.status(429).json({
        success: false,
        message: `Too many failed attempts (${MAX_ATTEMPTS}). Please request a new verification code.`,
      });
    }

    if (status === 'EXPIRED') {
      await writeAuditLog(uid, email, 'OTP_EXPIRED', auditMeta);
      return res.status(400).json({ success: false, message: 'Verification code has expired. Please request a new one.' });
    }

    if (status === 'WRONG_OTP') {
      await writeAuditLog(uid, email, 'OTP_WRONG', { attempt: newAttempts, remaining, ...auditMeta });

      if (remaining <= 0) {
        await writeAuditLog(uid, email, 'ACCOUNT_LOCKED', { reason: 'MAX_ATTEMPTS', ...auditMeta });
      }

      return res.status(400).json({
        success: false,
        message: remaining > 0
          ? `Incorrect verification code. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining.`
          : `Too many failed attempts. Please request a new verification code.`,
      });
    }

    // status === 'SUCCESS'
    // 4. Fetch user profile
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const role = userData.role || 'customer';

    // 5. Issue JWT tokens
    const tokens = generateTokens({ uid, email, role });

    // 6. Emit LOGIN_SUCCESS with OTP_VERIFIED audit events
    await writeAuditLog(uid, email, 'OTP_VERIFIED', { loginSessionId, ...device });
    await writeAuditLog(uid, email, 'LOGIN_SUCCESS', {
      loginSessionId,
      role,
      loginTime: new Date().toISOString(),
      ...device,
    });

    return res.status(200).json({
      success: true,
      message: 'Login verification successful.',
      user: {
        uid,
        email,
        name: userData.fullName || userData.name || '',
        phone: userData.phoneNumber || userData.phone || '',
        role,
        userAddress: userData.userAddress || userData.address || '',
        userAddressType: userData.userAddressType || 'Home',
        hasCompletedAddressSetup: userData.hasCompletedAddressSetup ?? false,
      },
      ...tokens,
    });
  } catch (error) {
    console.error('verifyLoginOtp error:', error.message);
    return res.status(500).json({ success: false, message: 'Verification failed. Please try again.', error: error.message });
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
  sendLoginOtp,
  verifyLoginOtp,
};

const adminAuth = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin access scope required.'
    });
  }
  next();
};

module.exports = adminAuth;

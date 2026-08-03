const vendorAuth = (req, res, next) => {
  if (!req.user || (req.user.role !== 'vendor' && req.user.role !== 'admin')) {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Vendor access scope required.'
    });
  }
  next();
};

module.exports = vendorAuth;

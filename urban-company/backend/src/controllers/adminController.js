const { db } = require('../config/firebase');

const getSystemStats = async (req, res) => {
  try {
    const usersSnap = await db.collection('users').get();
    const vendorsSnap = await db.collection('vendors').get();
    const bookingsSnap = await db.collection('bookings').get();
    
    // Sum amounts
    let totalRevenue = 0;
    bookingsSnap.forEach(doc => {
      const amt = doc.data().totalAmount || 0;
      totalRevenue += parseFloat(amt);
    });

    return res.status(200).json({
      success: true,
      stats: {
        totalUsers: usersSnap.size,
        totalVendors: vendorsSnap.size,
        totalBookings: bookingsSnap.size,
        totalRevenue
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Analytics aggregation error', error: error.message });
  }
};

const approveVendor = async (req, res) => {
  try {
    const { vendorId } = req.body;

    const vendorAppRef = db.collection('vendor_applications').doc(vendorId);
    const doc = await vendorAppRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Vendor application not found' });
    }

    await vendorAppRef.update({ status: 'APPROVED', approvedAt: new Date() });

    // Also update vendor user profile status
    await db.collection('vendors').doc(vendorId).set({
      uid: vendorId,
      status: 'APPROVED',
      updatedAt: new Date()
    }, { merge: true });

    return res.status(200).json({ success: true, message: 'Vendor application approved successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Approval processing failure', error: error.message });
  }
};

const rejectVendor = async (req, res) => {
  try {
    const { vendorId, reason } = req.body;

    const vendorAppRef = db.collection('vendor_applications').doc(vendorId);
    const doc = await vendorAppRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Vendor application not found' });
    }

    await vendorAppRef.update({ status: 'REJECTED', rejectionReason: reason || 'Incomplete KYC documents', rejectedAt: new Date() });

    return res.status(200).json({ success: true, message: 'Vendor application rejected' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Rejection processing failure', error: error.message });
  }
};

module.exports = {
  getSystemStats,
  approveVendor,
  rejectVendor
};

const { db } = require('../config/firebase');

const findBestVendorForBooking = async (bookingId) => {
  try {
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new Error('Booking not found');
    }

    const bookingData = bookingDoc.data();
    const serviceCategory = bookingData.serviceId; // e.g. Cleaning, Plumbing

    // Find all approved vendors matching the category who are currently ONLINE
    const vendorsQuery = await db.collection('vendors')
      .where('status', '==', 'APPROVED')
      .where('isOnline', '==', true)
      .where('category', '==', serviceCategory)
      .get();

    if (vendorsQuery.empty) {
      console.log(`No matching online vendors found for Booking ${bookingId}`);
      return null;
    }

    let candidateVendors = [];

    vendorsQuery.forEach(doc => {
      const data = doc.data();
      candidateVendors.push({ id: doc.id, ...data });
    });

    // Sort priority logic:
    // 1. Highest rating first (rating descending)
    // 2. Least active jobs count (activeJobs ascending)
    candidateVendors.sort((a, b) => {
      const ratingDiff = (b.rating || 0) - (a.rating || 0);
      if (ratingDiff !== 0) return ratingDiff;

      return (a.activeJobs || 0) - (b.activeJobs || 0);
    });

    const bestVendor = candidateVendors[0];
    
    // Assign vendor to booking
    await db.collection('bookings').doc(bookingId).update({
      vendorId: bestVendor.id,
      status: 'ASSIGNED',
      assignedAt: new Date()
    });

    // Add timeline log
    await db.collection('booking_timeline').add({
      bookingId,
      status: 'ASSIGNED',
      description: `Auto-assignment algorithm matched Booking with Vendor ${bestVendor.name || bestVendor.id}.`,
      timestamp: new Date()
    });

    console.log(`Successfully auto-assigned Booking ${bookingId} to Vendor ${bestVendor.id}`);
    return bestVendor;
  } catch (error) {
    console.error('Auto-assignment failed:', error.message);
    return null;
  }
};

module.exports = {
  findBestVendorForBooking
};

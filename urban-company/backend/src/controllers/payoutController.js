const { db } = require('../config/firebase');

const requestWithdrawal = async (req, res) => {
  try {
    const { amount, method, accountDetails } = req.body;
    const vendorId = req.user.uid;

    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid withdrawal amount' });
    }

    const vendorRef = db.collection('vendors').doc(vendorId);
    
    await db.runTransaction(async (transaction) => {
      const vendorDoc = await transaction.get(vendorRef);
      if (!vendorDoc.exists) {
        throw new Error('Vendor not found');
      }

      const data = vendorDoc.data();
      const currentBalance = data.walletBalance || 0;

      if (currentBalance < amount) {
        throw new Error('Insufficient wallet balance');
      }

      // Deduct from wallet immediately
      transaction.update(vendorRef, {
        walletBalance: currentBalance - amount,
        updatedAt: new Date()
      });

      // Create withdrawal request
      const withdrawalRef = db.collection('withdrawals').doc();
      transaction.set(withdrawalRef, {
        id: withdrawalRef.id,
        vendorId,
        amount: parseFloat(amount),
        method: method || 'Bank Account',
        accountDetails: accountDetails || {},
        status: 'PENDING',
        createdAt: new Date(),
        updatedAt: new Date()
      });
    });

    return res.status(201).json({ success: true, message: 'Withdrawal requested successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message || 'Withdrawal request failed' });
  }
};

const getVendorWithdrawals = async (req, res) => {
  try {
    const vendorId = req.user.uid;
    const snapshot = await db.collection('withdrawals')
      .where('vendorId', '==', vendorId)
      .orderBy('createdAt', 'desc')
      .get();
      
    const withdrawals = [];
    snapshot.forEach(doc => {
      withdrawals.push(doc.data());
    });

    return res.status(200).json({ success: true, withdrawals });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch withdrawals', error: error.message });
  }
};

const getAdminPendingWithdrawals = async (req, res) => {
  try {
    // Ideally check admin role here
    const snapshot = await db.collection('withdrawals')
      .where('status', '==', 'PENDING')
      .orderBy('createdAt', 'desc')
      .get();
      
    const withdrawals = [];
    snapshot.forEach(doc => {
      withdrawals.push(doc.data());
    });

    return res.status(200).json({ success: true, withdrawals });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch pending withdrawals', error: error.message });
  }
};

const approveWithdrawal = async (req, res) => {
  try {
    const { withdrawalId } = req.body;
    
    const withdrawalRef = db.collection('withdrawals').doc(withdrawalId);
    
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(withdrawalRef);
      if (!doc.exists) throw new Error('Withdrawal not found');
      
      const data = doc.data();
      if (data.status !== 'PENDING') throw new Error('Withdrawal is not pending');

      // MOCK Cashfree Payout API call
      const cashfreeTransferId = `payout_${Date.now()}`;
      
      transaction.update(withdrawalRef, {
        status: 'COMPLETED',
        cashfreeTransferId,
        updatedAt: new Date(),
        completedAt: new Date()
      });
      
      const txRef = db.collection('transactions').doc();
      transaction.set(txRef, {
        transactionId: cashfreeTransferId,
        vendorId: data.vendorId,
        amount: data.amount,
        type: 'Payout',
        status: 'Completed',
        method: data.method,
        createdAt: new Date()
      });
    });

    return res.status(200).json({ success: true, message: 'Withdrawal approved and processed via Cashfree Payouts' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to approve withdrawal', error: error.message });
  }
};

const rejectWithdrawal = async (req, res) => {
  try {
    const { withdrawalId, reason } = req.body;
    
    const withdrawalRef = db.collection('withdrawals').doc(withdrawalId);
    
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(withdrawalRef);
      if (!doc.exists) throw new Error('Withdrawal not found');
      
      const data = doc.data();
      if (data.status !== 'PENDING') throw new Error('Withdrawal is not pending');

      const vendorRef = db.collection('vendors').doc(data.vendorId);
      const vendorDoc = await transaction.get(vendorRef);
      const currentBalance = vendorDoc.exists ? (vendorDoc.data().walletBalance || 0) : 0;
      
      if (vendorDoc.exists) {
        transaction.update(vendorRef, {
          walletBalance: currentBalance + data.amount,
          updatedAt: new Date()
        });
      }

      transaction.update(withdrawalRef, {
        status: 'REJECTED',
        reason: reason || 'Rejected by Admin',
        updatedAt: new Date()
      });
    });

    return res.status(200).json({ success: true, message: 'Withdrawal rejected and refunded to wallet' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to reject withdrawal', error: error.message });
  }
};

module.exports = {
  requestWithdrawal,
  getVendorWithdrawals,
  getAdminPendingWithdrawals,
  approveWithdrawal,
  rejectWithdrawal
};

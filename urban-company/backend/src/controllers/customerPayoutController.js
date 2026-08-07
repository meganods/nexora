const { db } = require('../config/firebase');

const requestCustomerWithdrawal = async (req, res) => {
  try {
    const { amount, bankAccount, upiId } = req.body;
    const userId = req.user.uid;

    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid withdrawal amount' });
    }

    const walletRef = db.collection('wallet').doc(userId);
    const withdrawId = 'WD' + Math.floor(10000 + Math.random() * 90000);

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      let currentBalance = 0;
      let withdrawableBalance = 0;

      if (walletDoc.exists && walletDoc.data() != null) {
        const d = walletDoc.data();
        currentBalance = parseFloat(d.balance || 0);
        withdrawableBalance = parseFloat(d.withdrawableBalance || d.balance || 0);
      } else {
        throw new Error('Wallet not found');
      }

      if (withdrawableBalance < amount) {
        throw new Error('Insufficient withdrawable balance');
      }

      // Deduct from wallet immediately
      transaction.update(walletRef, {
        balance: currentBalance - amount,
        withdrawableBalance: withdrawableBalance - amount,
        updatedAt: new Date()
      });

      // Create withdrawal request
      const reqRef = db.collection('withdraw_requests').doc(withdrawId);
      transaction.set(reqRef, {
        withdrawId,
        userId,
        amount: parseFloat(amount),
        bankAccount: bankAccount || upiId || 'Bank Transfer',
        status: 'Pending',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });

      // Add to transaction history
      const txRef = db.collection('transactions').doc();
      transaction.set(txRef, {
        id: txRef.id,
        userId,
        amount: parseFloat(amount),
        isCredit: false,
        type: 'Withdrawal',
        status: 'Pending',
        paymentMethod: bankAccount ? 'Bank Account' : 'UPI',
        createdAt: new Date().toISOString()
      });
    });

    return res.status(201).json({ success: true, withdrawId, message: 'Withdrawal requested successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message || 'Withdrawal request failed' });
  }
};

const getCustomerWithdrawals = async (req, res) => {
  try {
    const userId = req.user.uid;
    const snapshot = await db.collection('withdraw_requests')
      .where('userId', '==', userId)
      .get();
      
    const withdrawals = [];
    snapshot.forEach(doc => {
      withdrawals.push(doc.data());
    });

    // Sort manually by date since composite index might not exist yet
    withdrawals.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return res.status(200).json({ success: true, withdrawals });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch withdrawals', error: error.message });
  }
};

const approveCustomerWithdrawal = async (req, res) => {
  try {
    const { withdrawId } = req.body;
    const reqRef = db.collection('withdraw_requests').doc(withdrawId);

    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(reqRef);
      if (!doc.exists) throw new Error('Withdrawal request not found');

      const data = doc.data();
      if (data.status !== 'Pending') throw new Error('Withdrawal is not pending');

      transaction.update(reqRef, {
        status: 'Completed',
        updatedAt: new Date().toISOString()
      });

      // Find the corresponding transaction log and mark it Completed
      const txs = await db.collection('transactions')
        .where('userId', '==', data.userId)
        .where('type', '==', 'Withdrawal')
        .where('amount', '==', data.amount)
        .where('status', '==', 'Pending')
        .get();

      txs.forEach(tDoc => {
        transaction.update(tDoc.ref, { status: 'Completed' });
      });
    });

    return res.status(200).json({ success: true, message: 'Withdrawal approved successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to approve withdrawal', error: error.message });
  }
};

const rejectCustomerWithdrawal = async (req, res) => {
  try {
    const { withdrawId, reason } = req.body;
    const reqRef = db.collection('withdraw_requests').doc(withdrawId);

    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(reqRef);
      if (!doc.exists) throw new Error('Withdrawal request not found');

      const data = doc.data();
      if (data.status !== 'Pending') throw new Error('Withdrawal is not pending');

      const walletRef = db.collection('wallet').doc(data.userId);
      const walletDoc = await transaction.get(walletRef);
      const currentBalance = walletDoc.exists ? parseFloat(walletDoc.data().balance || 0) : 0;
      const withdrawableBalance = walletDoc.exists ? parseFloat(walletDoc.data().withdrawableBalance || 0) : 0;

      transaction.update(walletRef, {
        balance: currentBalance + data.amount,
        withdrawableBalance: withdrawableBalance + data.amount,
        updatedAt: new Date()
      });

      transaction.update(reqRef, {
        status: 'Failed',
        reason: reason || 'Rejected by Admin',
        updatedAt: new Date().toISOString()
      });

      // Find pending transaction log and mark it Failed
      const txs = await db.collection('transactions')
        .where('userId', '==', data.userId)
        .where('type', '==', 'Withdrawal')
        .where('amount', '==', data.amount)
        .where('status', '==', 'Pending')
        .get();

      txs.forEach(tDoc => {
        transaction.update(tDoc.ref, { status: 'Failed' });
      });
    });

    return res.status(200).json({ success: true, message: 'Withdrawal rejected and funds returned' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to reject withdrawal', error: error.message });
  }
};

module.exports = {
  requestCustomerWithdrawal,
  getCustomerWithdrawals,
  approveCustomerWithdrawal,
  rejectCustomerWithdrawal
};

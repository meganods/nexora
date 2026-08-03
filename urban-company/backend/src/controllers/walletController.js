const { db } = require('../config/firebase');

const getWalletDetails = async (req, res) => {
  try {
    const userId = req.user.uid;
    const walletSnap = await db.collection('wallets').doc(userId).get();

    if (!walletSnap.exists) {
      // Create fresh empty wallet
      const newWallet = {
        userId,
        balance: 0,
        currency: 'INR',
        updatedAt: new Date()
      };
      await db.collection('wallets').doc(userId).set(newWallet);
      return res.status(200).json({ success: true, wallet: newWallet, transactions: [] });
    }

    const txSnap = await db.collection('transactions')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .get();

    const transactions = txSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    return res.status(200).json({
      success: true,
      wallet: walletSnap.data(),
      transactions
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Wallet retrieval error', error: error.message });
  }
};

const creditReferralReward = async (req, res) => {
  try {
    const { userId, rewardAmount } = req.body;

    const walletRef = db.collection('wallets').doc(userId);
    await db.runTransaction(async (transaction) => {
      const sfDoc = await transaction.get(walletRef);
      let currentBalance = 0;
      if (sfDoc.exists) {
        currentBalance = sfDoc.data().balance || 0;
      }
      const newBalance = currentBalance + parseFloat(rewardAmount);
      transaction.set(walletRef, { userId, balance: newBalance, updatedAt: new Date() }, { merge: true });

      // Add to transaction log
      const txRef = db.collection('transactions').doc();
      transaction.set(txRef, {
        userId,
        amount: rewardAmount,
        type: 'REFERRAL_CREDIT',
        description: 'Referral reward credit successfully processed.',
        timestamp: new Date()
      });
    });

    return res.status(200).json({ success: true, message: 'Referral reward credited successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Reward credit failed', error: error.message });
  }
};

module.exports = {
  getWalletDetails,
  creditReferralReward
};

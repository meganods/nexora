const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase locally using service account
const serviceAccount = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', '..', '.env'), 'utf8')
    .match(/FIREBASE_SERVICE_ACCOUNT=(.+)/)[1]
    .replace(/\\n/g, '\n')
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  console.log('Fetching pending customer withdrawal requests...');
  const snapshot = await db.collection('withdraw_requests').where('status', '==', 'Pending').get();
  
  if (snapshot.empty) {
    console.log('No pending customer withdrawal requests found.');
    process.exit(0);
  }

  for (const doc of snapshot.docs) {
    const data = doc.data();
    console.log(`Approving request ${doc.id} for amount ₹${data.amount}...`);
    
    await db.runTransaction(async (transaction) => {
      transaction.update(doc.ref, {
        status: 'Completed',
        updatedAt: new Date().toISOString()
      });

      // Find pending transaction and complete it
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
    
    console.log(`Request ${doc.id} successfully marked COMPLETED!`);
  }
  
  process.exit(0);
}

run().catch(console.error);

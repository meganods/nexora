const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

let db;
let auth;
let storage;
let messaging;

try {
  const serviceAccountString = process.env.FIREBASE_SERVICE_ACCOUNT;
  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || 'urbancompany-e7c79.firebasestorage.app';

  if (serviceAccountString) {
    let serviceAccount;
    let useCert = false;
    try {
      serviceAccount = JSON.parse(serviceAccountString);
      if (serviceAccount && serviceAccount.private_key) {
        useCert = true;
      }
    } catch (e) {
      serviceAccount = serviceAccountString; // treat as filePath
      useCert = true;
    }

    if (useCert) {
      admin.initializeApp({
        credential: typeof serviceAccount === 'string' 
            ? admin.credential.cert(require(serviceAccount))
            : admin.credential.cert(serviceAccount),
        storageBucket: storageBucket,
      });
    } else {
      admin.initializeApp({
        projectId: 'urbancompany-e7c79',
        storageBucket: storageBucket,
      });
    }
  } else {
    // Graceful fallback to application default credentials or local testing emulation
    admin.initializeApp({
      projectId: 'urbancompany-e7c79',
      storageBucket: storageBucket,
    });
  }

  db = admin.firestore();
  auth = admin.auth();
  storage = admin.storage();
  messaging = admin.messaging();

  console.log('Firebase Admin initialized successfully.');
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
}

module.exports = {
  admin,
  db,
  auth,
  storage,
  messaging
};

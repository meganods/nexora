const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

let serviceAccountString = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountString) {
  console.error("FIREBASE_SERVICE_ACCOUNT env variable not found!");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(serviceAccountString);
} catch (e) {
  serviceAccount = require(serviceAccountString);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const createAdminUser = async () => {
  try {
    console.log('Creating admin user in Firebase Auth...');
    
    const userRecord = await admin.auth().createUser({
      email: 'admin.example@gmail.com',
      emailVerified: true,
      password: 'admin123',
      displayName: 'System Admin',
      disabled: false,
    });
    
    console.log(`Successfully created admin user: ${userRecord.uid}`);
    
    // Also create the corresponding document in Firestore if needed
    const db = admin.firestore();
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: 'admin.example@gmail.com',
      fullName: 'System Admin',
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log('Admin document written to Firestore.');
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('Admin email already exists in Firebase Auth. You can log in directly!');
      process.exit(0);
    } else {
      console.error('Error creating admin user:', error);
      process.exit(1);
    }
  }
};

createAdminUser();

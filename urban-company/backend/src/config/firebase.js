const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

let db;
let auth;
let storage;
let messaging;
let isMock = false;

// ─── Mock Database & Auth Services ───────────────────────────────────────────
class MockDocumentReference {
  constructor(collectionPath, docId, mockDb) {
    this.collectionPath = collectionPath;
    this.id = docId;
    this.mockDb = mockDb;
  }
  async get() {
    const data = this.mockDb.getData(this.collectionPath, this.id);
    return {
      exists: data !== undefined,
      data: () => data,
      ref: this,
    };
  }
  async set(data, options) {
    this.mockDb.setData(this.collectionPath, this.id, data, options);
  }
  async update(data) {
    this.mockDb.updateData(this.collectionPath, this.id, data);
  }
  async delete() {
    this.mockDb.deleteData(this.collectionPath, this.id);
  }
}

class MockCollectionReference {
  constructor(collectionPath, mockDb) {
    this.path = collectionPath;
    this.mockDb = mockDb;
    this._queries = [];
  }
  doc(docId) {
    return new MockDocumentReference(this.path, docId || Math.random().toString(36).substring(7), this.mockDb);
  }
  where(field, operator, value) {
    const query = new MockCollectionReference(this.path, this.mockDb);
    query._queries = [...this._queries, { field, operator, value }];
    return query;
  }
  limit(num) {
    return this;
  }
  async get() {
    let results = this.mockDb.getAllData(this.path);
    for (const q of this._queries) {
      results = results.filter(item => {
        const val = item[q.field];
        if (q.operator === '==') return val === q.value;
        return true;
      });
    }
    return {
      empty: results.length === 0,
      docs: results.map(r => ({
        id: r.id,
        data: () => r,
        ref: new MockDocumentReference(this.path, r.id, this.mockDb),
      })),
    };
  }
  async add(data) {
    const id = Math.random().toString(36).substring(7);
    this.mockDb.setData(this.path, id, data);
    return { id, ref: new MockDocumentReference(this.path, id, this.mockDb) };
  }
}

class MockFirestore {
  constructor() {
    this.store = {};
  }
  collection(collectionPath) {
    return new MockCollectionReference(collectionPath, this);
  }
  getData(collectionPath, docId) {
    if (!this.store[collectionPath]) return undefined;
    return this.store[collectionPath][docId];
  }
  setData(collectionPath, docId, data, options) {
    if (!this.store[collectionPath]) this.store[collectionPath] = {};
    const existing = this.store[collectionPath][docId] || {};
    if (options && options.merge) {
      this.store[collectionPath][docId] = { ...existing, ...data, id: docId };
    } else {
      this.store[collectionPath][docId] = { ...data, id: docId };
    }
  }
  updateData(collectionPath, docId, data) {
    if (!this.store[collectionPath]) this.store[collectionPath] = {};
    const existing = this.store[collectionPath][docId] || {};
    this.store[collectionPath][docId] = { ...existing, ...data, id: docId };
  }
  deleteData(collectionPath, docId) {
    if (this.store[collectionPath]) {
      delete this.store[collectionPath][docId];
    }
  }
  getAllData(collectionPath) {
    if (!this.store[collectionPath]) return [];
    return Object.values(this.store[collectionPath]);
  }
  async runTransaction(updateFunction) {
    const transaction = {
      get: async (ref) => ref.get(),
      set: (ref, data) => ref.set(data),
      update: (ref, data) => ref.update(data),
      delete: (ref) => ref.delete(),
    };
    return updateFunction(transaction);
  }
}

class MockAuth {
  async verifyIdToken(idToken) {
    try {
      const jwt = require('jsonwebtoken');
      const decoded = jwt.decode(idToken);
      if (decoded) {
        return {
          uid: decoded.user_id || decoded.sub || decoded.uid || 'test-uid',
          email: decoded.email || 'test@example.com',
          name: decoded.name || 'Test User',
          role: decoded.role || 'customer',
        };
      }
    } catch (_) {}
    return {
      uid: 'mock-uid-123',
      email: 'mockuser@example.com',
      name: 'Mock User',
      role: 'customer',
    };
  }
  async createUser(properties) {
    return {
      uid: properties.uid || 'mock-uid-123',
      email: properties.email,
      displayName: properties.displayName,
    };
  }
  async setCustomUserClaims(uid, claims) {
    return;
  }
  async updateUser(uid, properties) {
    return { uid };
  }
}

// ─── Firebase Admin SDK Initialization ────────────────────────────────────────
try {
  const serviceAccountString = process.env.FIREBASE_SERVICE_ACCOUNT;
  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || 'urbancompany-e7c79.firebasestorage.app';

  let useCert = false;
  let serviceAccount;

  if (serviceAccountString) {
    try {
      serviceAccount = JSON.parse(serviceAccountString);
      if (serviceAccount && serviceAccount.private_key) {
        useCert = true;
      }
    } catch (e) {
      serviceAccount = serviceAccountString; // treat as file path
      useCert = true;
    }
  }

  if (useCert) {
    admin.initializeApp({
      credential: typeof serviceAccount === 'string'
          ? admin.credential.cert(require(serviceAccount))
          : admin.credential.cert(serviceAccount),
      storageBucket: storageBucket,
    });
    db = admin.firestore();
    auth = admin.auth();
    storage = admin.storage();
    messaging = admin.messaging();
    console.log('Firebase Admin initialized with production certificate.');
  } else {
    // Fallback to local Mock implementation to allow development without GCP credentials
    isMock = true;
    db = new MockFirestore();
    auth = new MockAuth();
    storage = {};
    messaging = {};
    console.log('⚠️ Running Firebase in MOCK mode (No valid service account private_key found).');
  }
} catch (error) {
  console.error('Error initializing Firebase Admin SDK, falling back to mock:', error);
  isMock = true;
  db = new MockFirestore();
  auth = new MockAuth();
  storage = {};
  messaging = {};
}

module.exports = {
  admin,
  db,
  auth,
  storage,
  messaging,
  isMock,
};

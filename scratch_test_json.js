require('dotenv').config({ path: 'urban-company/backend/.env' });
const val = process.env.FIREBASE_SERVICE_ACCOUNT;
console.log('Original value:', val.substring(0, 50));
try {
  const cleanedString = val.replace(/\\n/g, '\n');
  const parsed = JSON.parse(cleanedString);
  console.log('Parse successful!');
} catch (e) {
  console.log('Parse failed:', e.message);
}

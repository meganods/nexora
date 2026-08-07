require('dotenv').config();
const fs = require('fs');

let val = process.env.FIREBASE_SERVICE_ACCOUNT;
if (val.startsWith("'") && val.endsWith("'")) val = val.slice(1, -1);

try {
  // Let's try to parse it. If it fails, we will clean it.
  val = val.replace(/\\\\n/g, '\\n'); // fix double escaping
  const parsed = JSON.parse(val);
  console.log("Cleaned successfully");
  
  // write back to .env
  let envFile = fs.readFileSync('.env', 'utf8');
  envFile = envFile.replace(/FIREBASE_SERVICE_ACCOUNT=.*/, `FIREBASE_SERVICE_ACCOUNT='${JSON.stringify(parsed)}'`);
  fs.writeFileSync('.env', envFile);
} catch (e) {
  console.log("Still failed to parse:", e.message);
}

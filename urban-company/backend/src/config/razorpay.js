const Razorpay = require('razorpay');
const dotenv = require('dotenv');

dotenv.config();

let razorpay;

try {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_yourkeyid',
    key_secret: process.env.RAZORPAY_KEY_SECRET || 'yourkeysecret',
  });
  console.log('Razorpay Gateway initialized.');
} catch (error) {
  console.error('Error instantiating Razorpay SDK:', error);
}

module.exports = razorpay;

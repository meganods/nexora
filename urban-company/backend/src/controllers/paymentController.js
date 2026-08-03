const crypto = require('crypto');
const razorpay = require('../config/razorpay');
const { db } = require('../config/firebase');

const createOrder = async (req, res) => {
  try {
    const { amount, bookingId } = req.body;
    
    // Amount in Razorpay expects paisa (e.g. ₹100 is 10000 paisa)
    const options = {
      amount: parseInt(amount * 100, 10),
      currency: 'INR',
      receipt: `receipt_${bookingId}`,
    };

    if (!razorpay) {
      // Fallback response for offline or emulated testing if Razorpay keys are not provided
      return res.status(200).json({
        success: true,
        message: 'Order emulated (Razorpay not configured)',
        order: { id: `order_emu_${bookingId}`, amount: options.amount }
      });
    }

    const order = await razorpay.orders.create(options);

    // Track order creation in Firestore
    await db.collection('payments').add({
      orderId: order.id,
      bookingId,
      amount,
      status: 'CREATED',
      createdAt: new Date(),
    });

    return res.status(201).json({
      success: true,
      order
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Order Creation Failed', error: error.message });
  }
};

const verifyPaymentSignature = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingId } = req.body;

    const secret = process.env.RAZORPAY_KEY_SECRET || 'yourkeysecret';
    const text = `${razorpay_order_id}|${razorpay_payment_id}`;
    
    const generated_signature = crypto
      .createHmac('sha256', secret)
      .update(text)
      .digest('hex');

    if (generated_signature === razorpay_signature) {
      // Update payment document in Firestore
      const paymentQuery = await db.collection('payments')
        .where('orderId', '==', razorpay_order_id)
        .limit(1)
        .get();

      if (!paymentQuery.empty) {
        await paymentQuery.docs[0].reference.update({
          paymentId: razorpay_payment_id,
          status: 'SUCCESS',
          signature: razorpay_signature,
          updatedAt: new Date()
        });
      }

      // Update Booking status to CONFIRMED
      const bookingRef = db.collection('bookings').doc(bookingId);
      await bookingRef.update({ status: 'CONFIRMED' });

      // Add timeline checkpoint
      await db.collection('booking_timeline').add({
        bookingId,
        status: 'CONFIRMED',
        description: 'Payment verified successfully. Booking is now confirmed.',
        timestamp: new Date()
      });

      return res.status(200).json({ success: true, message: 'Signature validation successful' });
    } else {
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Signature verification error', error: error.message });
  }
};

const handleWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET || 'yourwebhooksecret';

    const hmac = crypto.createHmac('sha256', secret);
    hmac.update(JSON.stringify(req.body));
    const generated = hmac.digest('hex');

    if (generated === signature) {
      const event = req.body.event;
      // Handle different hook states (payment.captured, payment.failed)
      if (event === 'payment.captured') {
        const payload = req.body.payload.payment.entity;
        // logic to reconcile payload.order_id 
      }
      return res.status(200).json({ status: 'OK' });
    } else {
      return res.status(400).json({ message: 'Invalid webhook signature' });
    }
  } catch (error) {
    return res.status(500).json({ message: 'Webhook processing error', error: error.message });
  }
};

module.exports = {
  createOrder,
  verifyPaymentSignature,
  handleWebhook
};

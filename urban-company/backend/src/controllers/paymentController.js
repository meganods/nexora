const crypto = require('crypto');
const { db } = require('../config/firebase');

// Cashfree Configuration
const CASHFREE_API_ID = process.env.CASHFREE_API_ID;
const CASHFREE_SECRET_KEY = process.env.CASHFREE_SECRET_KEY;
const CASHFREE_ENV = process.env.CASHFREE_ENV || 'sandbox';
const CASHFREE_BASE_URL = CASHFREE_ENV === 'production' 
  ? 'https://api.cashfree.com/pg' 
  : 'https://sandbox.cashfree.com/pg';

// Helper: Process successful payment post-flow
const processPaymentSuccess = async (orderId, paymentDetails) => {
  const paymentRef = db.collection('payments').doc(orderId);
  const paymentDoc = await paymentRef.get();
  if (!paymentDoc.exists) return;

  const paymentData = paymentDoc.data();
  if (paymentData.status === 'SUCCESS') {
    return; // Already processed
  }

  // Update status to SUCCESS in payments collection
  await paymentRef.update({
    status: 'SUCCESS',
    updatedAt: new Date(),
    paymentDetails: paymentDetails || null
  });

  const { userId, bookingId, amount, walletUsed, couponCode, couponDiscount, bookingData, paymentType } = paymentData;

  if (paymentType === 'wallet_recharge') {
    // Add amount to wallet
    const walletRef = db.collection('wallet').doc(userId);
    const walletsRef = db.collection('wallets').doc(userId);
    
    const addWallet = async (ref) => {
      const doc = await ref.get();
      if (doc.exists) {
        const currentBal = doc.data().balance || 0;
        await ref.update({
          balance: currentBal + parseFloat(amount),
          updatedAt: new Date()
        });
      } else {
        await ref.set({
          userId,
          balance: parseFloat(amount),
          currency: 'INR',
          updatedAt: new Date()
        });
      }
    };
    await addWallet(walletRef);
    await addWallet(walletsRef);

    // Record Wallet Credit Transaction
    await db.collection('transactions').add({
      userId,
      transactionId: orderId,
      amount: parseFloat(amount),
      type: 'Wallet Recharge',
      isCredit: true,
      description: `Wallet recharge via Cashfree.`,
      status: 'Completed',
      paymentMethod: 'Cashfree',
      timestamp: new Date(),
      createdAt: new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true })
    });

    return; // Skip booking creation
  }

  // Create Booking if it doesn't exist
  if (bookingId) {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) {
      await bookingRef.set({
        id: bookingId,
        userId: userId,
        userEmail: (bookingData && bookingData.userEmail) || 'customer@nexora.com',
        userName: (bookingData && bookingData.userName) || 'Customer',
        userPhone: (bookingData && bookingData.userPhone) || '',
        userAddress: (bookingData && bookingData.userAddress) || '',
        shopName: (bookingData && bookingData.shopName) || 'CleanPro Services',
        price: `₹${(bookingData && bookingData.totalAmount) || amount}`,
        rawAmount: parseFloat((bookingData && bookingData.totalAmount) || amount),
        date: (bookingData && bookingData.date) || 'Tomorrow',
        time: (bookingData && bookingData.time) || '10:00 AM',
        paymentMethod: 'Cashfree',
        bookingStatus: 'Completed',
        status: 'assigned',
        notes: (bookingData && bookingData.notes) || '',
        couponCode: couponCode || null,
        createdAt: new Date(),
        completedAt: new Date(),
        vendorId: (bookingData && bookingData.vendorId) || 'v1',
        coverImage: (bookingData && bookingData.coverImage) || '',
      });

      // Seeding timeline
      await db.collection('booking_timeline').add({
        bookingId,
        status: 'CONFIRMED',
        description: 'Payment verified successfully via Cashfree. Booking is now confirmed.',
        timestamp: new Date()
      });
    }

    // Deduct Wallet Balance if used
    if (walletUsed && walletUsed > 0) {
      const walletRef = db.collection('wallet').doc(userId);
      const walletsRef = db.collection('wallets').doc(userId);
      
      const deductWallet = async (ref) => {
        const doc = await ref.get();
        if (doc.exists) {
          const currentBal = doc.data().balance || 0;
          await ref.update({
            balance: Math.max(0, currentBal - walletUsed),
            updatedAt: new Date()
          });
        }
      };
      await deductWallet(walletRef);
      await deductWallet(walletsRef);

      // Record Wallet Debit Transaction
      await db.collection('transactions').add({
        userId,
        amount: parseFloat(walletUsed),
        type: 'WALLET_DEBIT',
        description: `Wallet balance used for booking ${bookingId}.`,
        timestamp: new Date()
      });
    }

    // Create Cashfree Transaction Record
    await db.collection('transactions').add({
      transactionId: orderId,
      cashfreeOrderId: orderId,
      paymentSessionId: paymentData.paymentSessionId || '',
      bookingId: bookingId,
      userId: userId,
      vendorId: (bookingData && bookingData.vendorId) || 'v1',
      amount: parseFloat(amount),
      paymentMethod: 'Cashfree',
      paymentStatus: 'SUCCESS',
      currency: 'INR',
      couponCode: couponCode || '',
      walletUsed: parseFloat(walletUsed || 0),
      cashback: 0.0,
      createdAt: new Date()
    });

    // Create Invoice record (both invoice and invoices for safety)
    const invoiceData = {
      invoiceNumber: `INV-${bookingId.replace('NEX-', '')}`,
      bookingId: bookingId,
      userId: userId,
      userName: (bookingData && bookingData.userName) || 'Customer',
      gst: 52.0,
      platformFee: 29.0,
      discount: parseFloat(couponDiscount || 0),
      wallet: parseFloat(walletUsed || 0),
      grandTotal: parseFloat((bookingData && bookingData.totalAmount) || amount),
      pdfUrl: '',
      createdAt: new Date()
    };
    await db.collection('invoice').doc(bookingId).set(invoiceData);
    await db.collection('invoices').doc(bookingId).set(invoiceData);

    // Create Notifications
    const notifications = [
      { title: 'Payment Successful', message: `Your payment of ₹${amount} via Cashfree was successful.` },
      { title: 'Booking Confirmed', message: `Booking ${bookingId} has been confirmed.` },
      { title: 'Invoice Generated', message: `Invoice INV-${bookingId.replace('NEX-', '')} has been generated.` },
      { title: 'Vendor Assigned', message: `A professional partner has been assigned to your booking.` }
    ];

    if (walletUsed && walletUsed > 0) {
      notifications.push({ title: 'Wallet Updated', message: `₹${walletUsed} has been deducted from your wallet.` });
    }

    for (const notif of notifications) {
      await db.collection('notifications').add({
        userId,
        title: notif.title,
        message: notif.message,
        read: false,
        timestamp: new Date()
      });
    }

    // Update Vendor Earnings
    const vendorId = (bookingData && bookingData.vendorId) || 'v1';
    const totalBookAmount = parseFloat((bookingData && bookingData.totalAmount) || amount);
    await db.collection('vendor_earnings').add({
      vendorId,
      bookingId,
      amount: totalBookAmount,
      earnings: totalBookAmount * 0.85,
      commission: totalBookAmount * 0.15,
      status: 'earned',
      createdAt: new Date()
    });

    // Update Admin Reports
    await db.collection('admin_reports').add({
      bookingId,
      amount: totalBookAmount,
      commission: totalBookAmount * 0.15,
      revenue: totalBookAmount * 0.15,
      type: 'booking_payment',
      createdAt: new Date()
    });
  }
};

const createOrder = async (req, res) => {
  // Legacy Razorpay endpoint kept for fallback
  return res.status(400).json({ success: false, message: 'Please use Cashfree endpoints' });
};

const verifyPaymentSignature = async (req, res) => {
  // Legacy Razorpay signature verification
  return res.status(400).json({ success: false, message: 'Please use Cashfree endpoints' });
};

const handleWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-webhook-signature'];
    const timestamp = req.headers['x-webhook-timestamp'];

    if (!signature || !timestamp || !req.rawBody) {
      return res.status(400).json({ message: 'Missing webhook verification headers or body' });
    }

    // Webhook Signature verification
    const signatureData = timestamp + req.rawBody;
    const computedSignature = crypto
      .createHmac('sha256', CASHFREE_SECRET_KEY || '')
      .update(signatureData)
      .digest('base64');

    if (computedSignature !== signature) {
      return res.status(400).json({ message: 'Invalid webhook signature' });
    }

    const payload = req.body;
    const eventType = payload.type;
    const orderDetails = payload.data ? payload.data.order : null;

    if (orderDetails) {
      const orderId = orderDetails.order_id;
      const status = orderDetails.order_status;

      // Log payment events in Firestore
      await db.collection('payment_logs').add({
        orderId,
        eventType,
        status,
        payload,
        createdAt: new Date()
      });

      if (eventType === 'PAYMENT_SUCCESS' && status === 'PAID') {
        await processPaymentSuccess(orderId, payload.data.payment);
      } else if (eventType === 'PAYMENT_FAILED') {
        await db.collection('payments').doc(orderId).update({
          status: 'FAILED',
          updatedAt: new Date()
        });
      }
    }

    return res.status(200).json({ status: 'OK' });
  } catch (error) {
    return res.status(500).json({ message: 'Webhook processing error', error: error.message });
  }
};

const createCashfreeOrder = async (req, res) => {
  try {
    const { 
      amount, 
      bookingId, 
      customerEmail, 
      customerPhone, 
      paymentType,
      walletUsed,
      couponCode,
      couponDiscount,
      bookingData 
    } = req.body;
    const orderId = `cf_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    if (parseFloat(amount) === 0) {
      // Wallet-only payment
      await db.collection('payments').doc(orderId).set({
        orderId,
        userId: req.user.uid,
        bookingId: bookingId || null,
        amount: 0.0,
        walletUsed: parseFloat(walletUsed || 0),
        couponCode: couponCode || '',
        couponDiscount: parseFloat(couponDiscount || 0),
        paymentType: paymentType || 'booking_payment',
        status: 'SUCCESS',
        isMock: true,
        bookingData: bookingData || null,
        createdAt: new Date()
      });

      await processPaymentSuccess(orderId, { method: 'wallet' });

      return res.status(201).json({
        success: true,
        status: 'PAID',
        environment: CASHFREE_ENV,
        order: {
          order_id: orderId,
          order_amount: 0.0,
          payment_session_id: `wallet_session_${orderId}`
        }
      });
    }

    if (!CASHFREE_API_ID || !CASHFREE_SECRET_KEY) {
      // Mock fallback if keys not configured
      const mockOrder = {
        order_id: orderId,
        order_amount: parseFloat(amount),
        payment_session_id: `mock_session_${orderId}`,
      };

      await db.collection('payments').doc(orderId).set({
        orderId,
        userId: req.user.uid,
        bookingId: bookingId || null,
        amount: parseFloat(amount),
        walletUsed: parseFloat(walletUsed || 0),
        couponCode: couponCode || '',
        couponDiscount: parseFloat(couponDiscount || 0),
        paymentType: paymentType || 'booking_payment',
        status: 'CREATED',
        isMock: true,
        bookingData: bookingData || null,
        createdAt: new Date()
      });

      return res.status(201).json({
        success: true,
        isMock: true,
        environment: CASHFREE_ENV,
        order: mockOrder
      });
    }

    // Live Cashfree API call
    // NOTE: return_url is only used for web/browser fallback.
    // The Flutter SDK handles payment result via setCallback() on the app side.
    // We point it to the backend verify endpoint so server-side verification
    // also works if the user somehow ends up in a browser.
    const BACKEND_URL = process.env.BACKEND_URL || 'https://nexora-94dt.onrender.com';
    const response = await fetch(`${CASHFREE_BASE_URL}/orders`, {
      method: 'POST',
      headers: {
        'x-api-version': '2023-08-01',
        'x-client-id': CASHFREE_API_ID,
        'x-client-secret': CASHFREE_SECRET_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        order_amount: parseFloat(amount),
        order_currency: 'INR',
        order_id: orderId,
        customer_details: {
          customer_id: req.user.uid,
          customer_phone: customerPhone || '9999999999',
          customer_email: customerEmail || 'customer@nexora.com'
        },
        order_meta: {
          return_url: `${BACKEND_URL}/api/v1/payments/cashfree/callback?order_id={order_id}`
        }
      })
    });

    const responseData = await response.json();
    if (!response.ok) {
      throw new Error(responseData.message || 'Cashfree Order creation failed');
    }

    // Track order details in Firestore payments collection
    await db.collection('payments').doc(orderId).set({
      orderId,
      userId: req.user.uid,
      bookingId: bookingId || null,
      amount: parseFloat(amount),
      walletUsed: parseFloat(walletUsed || 0),
      couponCode: couponCode || '',
      couponDiscount: parseFloat(couponDiscount || 0),
      paymentType: paymentType || 'booking_payment',
      status: 'CREATED',
      isMock: false,
      bookingData: bookingData || null,
      paymentSessionId: responseData.payment_session_id || '',
      createdAt: new Date()
    });

    return res.status(201).json({
      success: true,
      environment: CASHFREE_ENV,
      order: {
        order_id: responseData.order_id,
        order_amount: responseData.order_amount,
        payment_session_id: responseData.payment_session_id,
        payment_link: responseData.payments ? responseData.payments.payment_link : (responseData.payment_link || null)
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Cashfree Order Creation Failed', error: error.message });
  }
};

const verifyCashfreePayment = async (req, res) => {
  try {
    const { orderId } = req.body;

    const paymentRef = db.collection('payments').doc(orderId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      return res.status(404).json({ success: false, message: 'Payment record not found' });
    }

    const paymentData = paymentDoc.data();
    if (paymentData.status === 'SUCCESS') {
      return res.status(200).json({ success: true, status: 'PAID', message: 'Payment already verified successfully' });
    }

    let isPaid = false;
    let paymentDetails = null;

    if (paymentData.isMock || !CASHFREE_API_ID || !CASHFREE_SECRET_KEY) {
      isPaid = true;
    } else {
      // Query Cashfree status from Cashfree servers
      const response = await fetch(`${CASHFREE_BASE_URL}/orders/${orderId}`, {
        method: 'GET',
        headers: {
          'x-api-version': '2023-08-01',
          'x-client-id': CASHFREE_API_ID,
          'x-client-secret': CASHFREE_SECRET_KEY,
          'Content-Type': 'application/json'
        }
      });

      const responseData = await response.json();
      if (response.ok) {
        isPaid = responseData.order_status === 'PAID';
        paymentDetails = responseData;
      }
    }

    if (isPaid) {
      await processPaymentSuccess(orderId, paymentDetails);
      return res.status(200).json({ success: true, status: 'PAID', message: 'Payment verified successfully' });
    } else {
      return res.status(200).json({ success: false, status: 'PENDING', message: 'Payment is pending or failed' });
    }
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Verification error', error: error.message });
  }
};

module.exports = {
  createOrder,
  verifyPaymentSignature,
  handleWebhook,
  createCashfreeOrder,
  verifyCashfreePayment
};

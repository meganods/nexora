const { db } = require('../config/firebase');

const createSupportTicket = async (req, res) => {
  try {
    const { title, description, category } = req.body;
    const userId = req.user.uid;
    const userEmail = req.user.email || '';

    const ticketRef = db.collection('support_tickets').doc();
    const newTicket = {
      id: ticketRef.id,
      userId,
      userEmail,
      title,
      description,
      category,
      status: 'OPEN',
      createdAt: new Date(),
    };

    await ticketRef.set(newTicket);

    return res.status(201).json({
      success: true,
      message: 'Support ticket opened successfully',
      ticket: newTicket
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Ticket generation error', error: error.message });
  }
};

const getMyTickets = async (req, res) => {
  try {
    const userId = req.user.uid;
    const ticketsSnap = await db.collection('support_tickets')
      .where('userId', '==', userId)
      .get();

    const tickets = ticketsSnap.docs.map(doc => doc.data());
    return res.status(200).json({ success: true, tickets });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to retrieve tickets', error: error.message });
  }
};

module.exports = {
  createSupportTicket,
  getMyTickets
};

const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse, sendPaginatedResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');

const router = express.Router();

// GET /api/v1/payments
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, user_email } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (req.user.role === 'student') {
      where.user_email = req.user.email;
    } else if (user_email) {
      where.user_email = user_email;
    }
    if (status) where.status = status;

    const [payments, total] = await Promise.all([
      prisma.payments.findMany({ where, skip, take: parseInt(limit), orderBy: { created_at: 'desc' } }),
      prisma.payments.count({ where }),
    ]);

    sendPaginatedResponse(res, payments, total, page, limit);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch payments.');
  }
});

// GET /api/v1/payments/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const payment = await prisma.payments.findUnique({
      where: { id: req.params.id },
      include: { enrollments: true },
    });
    if (!payment) return sendResponse(res, 404, false, 'Payment not found.');
    if (req.user.role === 'student' && payment.user_email !== req.user.email) {
      return sendResponse(res, 403, false, 'Access denied.');
    }
    sendResponse(res, 200, true, 'Payment fetched.', payment);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch payment.');
  }
});

// POST /api/v1/payments
router.post('/', authenticate, validateBody('user_email', 'plan', 'amount'), async (req, res) => {
  try {
    const { user_email, plan, amount, currency, razorpay_order_id, razorpay_payment_id, status } = req.body;
    const payment = await prisma.payments.create({
      data: {
        id: crypto.randomUUID(),
        user_email, plan, amount,
        currency: currency || 'INR',
        razorpay_order_id: razorpay_order_id || null,
        razorpay_payment_id: razorpay_payment_id || null,
        status: status || 'created',
      },
    });
    sendResponse(res, 201, true, 'Payment recorded.', payment);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to create payment.');
  }
});

// PUT /api/v1/payments/:id/status
router.put('/:id/status', authenticate, authorize('admin'), validateBody('status'), async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['created', 'paid', 'failed', 'refunded'];
    if (!validStatuses.includes(status)) {
      return sendResponse(res, 400, false, `Invalid status. Must be: ${validStatuses.join(', ')}`);
    }
    const payment = await prisma.payments.update({
      where: { id: req.params.id },
      data: { status, updated_at: new Date() },
    });
    sendResponse(res, 200, true, 'Payment status updated.', payment);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to update payment status.');
  }
});

// GET /api/v1/payments/stats/summary
router.get('/stats/summary', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const [total, paid, pending, failed] = await Promise.all([
      prisma.payments.count(),
      prisma.payments.count({ where: { status: 'paid' } }),
      prisma.payments.count({ where: { status: 'created' } }),
      prisma.payments.count({ where: { status: 'failed' } }),
    ]);
    sendResponse(res, 200, true, 'Payment stats fetched.', { total, paid, pending, failed });
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch payment stats.');
  }
});

module.exports = router;

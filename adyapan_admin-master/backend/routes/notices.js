const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse, sendPaginatedResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');

const router = express.Router();

// GET /api/v1/notices
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, channel, status } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (req.user.role === 'student' || req.user.role === 'teacher') {
      where.OR = [{ user_email: req.user.email }, { user_email: null }];
    }
    if (channel) where.channel = channel;
    if (status) where.status = status;

    const [notices, total] = await Promise.all([
      prisma.notifications.findMany({ where, skip, take: parseInt(limit), orderBy: { created_at: 'desc' } }),
      prisma.notifications.count({ where }),
    ]);

    sendPaginatedResponse(res, notices, total, page, limit);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch notices.');
  }
});

// GET /api/v1/notices/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const notice = await prisma.notifications.findUnique({ where: { id: req.params.id } });
    if (!notice) return sendResponse(res, 404, false, 'Notice not found.');
    sendResponse(res, 200, true, 'Notice fetched.', notice);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch notice.');
  }
});

// POST /api/v1/notices
router.post('/', authenticate, authorize('admin', 'principal', 'teacher'), validateBody('title', 'message'), async (req, res) => {
  try {
    const { title, message, user_email, channel } = req.body;
    const notice = await prisma.notifications.create({
      data: {
        id: crypto.randomUUID(),
        title, message,
        user_email: user_email || null,
        channel: channel || 'app',
        status: 'sent',
      },
    });
    sendResponse(res, 201, true, 'Notice created.', notice);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to create notice.');
  }
});

// POST /api/v1/notices/broadcast
router.post('/broadcast', authenticate, authorize('admin', 'principal'), validateBody('title', 'message'), async (req, res) => {
  try {
    const { title, message, channel } = req.body;
    const notice = await prisma.notifications.create({
      data: {
        id: crypto.randomUUID(),
        title, message,
        user_email: null,
        channel: channel || 'app',
        status: 'sent',
      },
    });
    sendResponse(res, 201, true, 'Broadcast notice sent.', notice);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to send broadcast notice.');
  }
});

// PUT /api/v1/notices/:id/read
router.put('/:id/read', authenticate, async (req, res) => {
  try {
    const notice = await prisma.notifications.update({
      where: { id: req.params.id },
      data: { read_at: new Date(), status: 'read' },
    });
    sendResponse(res, 200, true, 'Notice marked as read.', notice);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to mark notice as read.');
  }
});

// DELETE /api/v1/notices/:id
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await prisma.notifications.delete({ where: { id: req.params.id } });
    sendResponse(res, 200, true, 'Notice deleted.');
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to delete notice.');
  }
});

module.exports = router;

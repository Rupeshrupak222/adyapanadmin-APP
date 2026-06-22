const express = require('express');
const prisma = require('../lib/prisma');
const { authenticate, authorize } = require('../middleware/auth');
const router = express.Router();

// GET /api/v1/events — authenticated
router.get('/', authenticate, async (req, res) => {
  try {
    const { limit } = req.query;

    const events = await prisma.notifications.findMany({
      orderBy: { created_at: 'desc' },
      take: limit ? Math.min(parseInt(limit) || 50, 200) : 50,
    });

    res.json(events);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch events.' });
  }
});

// POST /api/v1/events — admin/principal only
router.post('/', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const { user_email, title, message, channel } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: 'title and message are required.' });
    }

    const event = await prisma.notifications.create({
      data: {
        id: require('crypto').randomUUID(),
        user_email: user_email || null,
        title: title.trim(),
        message: message.trim(),
        channel: channel || 'email',
        status: 'queued',
      },
    });

    res.status(201).json(event);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create event.' });
  }
});

// DELETE /api/v1/events/:id — admin only
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await prisma.notifications.delete({ where: { id: req.params.id } });
    res.json({ message: 'Event deleted' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Event not found.' });
    res.status(500).json({ error: 'Failed to delete event.' });
  }
});

module.exports = router;

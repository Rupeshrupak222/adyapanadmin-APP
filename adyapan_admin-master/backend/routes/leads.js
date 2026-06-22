const express = require('express');
const prisma = require('../lib/prisma');
const { authenticate, authorize } = require('../middleware/auth');
const router = express.Router();

// GET /api/v1/leads — admin only
router.get('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const leads = await prisma.leads.findMany({
      orderBy: { created_at: 'desc' },
    });
    res.json(leads);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch leads.' });
  }
});

// POST /api/v1/leads — public (enquiry/demo form submissions)
router.post('/', async (req, res) => {
  try {
    const { type, name, email, phone, school, city, message, class_level, interest } = req.body;

    if (!email || !String(email).includes('@')) {
      return res.status(400).json({ error: 'Valid email required.' });
    }

    const lead = await prisma.leads.create({
      data: {
        id: require('crypto').randomUUID().replace(/-/g, '').slice(0, 25),
        type: type || 'demo',
        name: name || null,
        email: String(email).toLowerCase().trim(),
        phone: phone || null,
        school: school || null,
        city: city || null,
        message: message || null,
        class_level: class_level || null,
        interest: interest || null,
      },
    });

    res.status(201).json({ ok: true, lead });
  } catch (err) {
    res.status(500).json({ error: 'Failed to submit lead.' });
  }
});

// DELETE /api/v1/leads/:id — admin only
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await prisma.leads.delete({ where: { id: req.params.id } });
    res.json({ message: 'Lead deleted' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Lead not found.' });
    res.status(500).json({ error: 'Failed to delete lead.' });
  }
});

module.exports = router;

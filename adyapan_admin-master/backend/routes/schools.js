const express = require('express');
const prisma = require('../lib/prisma');
const { authenticate, authorize } = require('../middleware/auth');
const router = express.Router();

// GET /api/v1/schools
router.get('/', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const schools = await prisma.school.findMany({
      orderBy: { created_at: 'desc' },
    });
    res.json(schools);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch schools.' });
  }
});

// GET /api/v1/schools/:id
router.get('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const school = await prisma.school.findUnique({
      where: { id: req.params.id },
    });

    if (!school) return res.status(404).json({ error: 'School not found' });
    res.json(school);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch school.' });
  }
});

// POST /api/v1/schools
router.post('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { name, email, phone, city, address, contact_person, status } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'School name is required.' });
    }

    const school = await prisma.school.create({
      data: {
        name: name.trim(),
        email: email || null,
        phone: phone || null,
        city: city || null,
        address: address || null,
        contact_person: contact_person || null,
        status: status || 'lead',
      },
    });

    res.status(201).json(school);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create school.' });
  }
});

// PUT /api/v1/schools/:id — whitelist fields, admin only
router.put('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { name, email, phone, city, address, contact_person, status } = req.body;
    const updateData = { updated_at: new Date() };
    if (name) updateData.name = name.trim();
    if (email !== undefined) updateData.email = email;
    if (phone !== undefined) updateData.phone = phone;
    if (city !== undefined) updateData.city = city;
    if (address !== undefined) updateData.address = address;
    if (contact_person !== undefined) updateData.contact_person = contact_person;
    if (status) updateData.status = status;

    const school = await prisma.school.update({
      where: { id: req.params.id },
      data: updateData,
    });
    res.json(school);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'School not found.' });
    res.status(500).json({ error: 'Failed to update school.' });
  }
});

// DELETE /api/v1/schools/:id
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await prisma.school.delete({ where: { id: req.params.id } });
    res.json({ message: 'School removed successfully' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'School not found.' });
    res.status(500).json({ error: 'Failed to delete school.' });
  }
});

module.exports = router;
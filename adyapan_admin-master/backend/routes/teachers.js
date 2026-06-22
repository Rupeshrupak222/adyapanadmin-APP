const express = require('express');
const prisma = require('../lib/prisma');
const { hashPassword } = require('../utils/password');
const { authenticate, authorize } = require('../middleware/auth');
const { sendResponse } = require('../utils/response');
const router = express.Router();

// Safe fields for teacher GET responses — never expose password/key hashes
const SAFE_SELECT = {
  id: true,
  schoolId: true,
  school_name: true,
  teacher_name: true,
  email: true,
  subject: true,
  phone: true,
  assigned_classes: true,
  status: true,
  last_login_at: true,
  created_at: true,
  updated_at: true,
};

// GET /api/v1/teachers
router.get('/', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const { search, schoolId } = req.query;
    const where = {};

    if (schoolId) where.schoolId = schoolId;
    if (search) {
      where.OR = [
        { teacher_name: { contains: search } },
        { subject: { contains: search } },
      ];
    }

    const teachers = await prisma.teacher.findMany({
      where,
      select: SAFE_SELECT,
      orderBy: { created_at: 'desc' },
    });

    res.json(teachers);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teachers.' });
  }
});

// GET /api/v1/teachers/:id
router.get('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const teacher = await prisma.teacher.findUnique({
      where: { id: req.params.id },
      select: SAFE_SELECT,
    });

    if (!teacher) return res.status(404).json({ error: 'Teacher not found' });
    res.json(teacher);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teacher.' });
  }
});

// POST /api/v1/teachers
router.post('/', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    const { teacher_name, email, subject, phone, schoolId, school_name, assigned_classes } = req.body;

    const name = (teacher_name || req.body.name || '').trim();
    const emailNorm = (email || '').toLowerCase().trim();

    if (!name || !emailNorm) {
      return res.status(400).json({ error: 'name and email are required.' });
    }

    // Generate secure credentials rather than accepting raw hashes from client
    const tempPassword = `ADY-${require('crypto').randomBytes(4).toString('hex').toUpperCase()}`;
    const tempKey = `KEY-${require('crypto').randomBytes(4).toString('hex').toUpperCase()}`;
    const pHash = await hashPassword(tempPassword);
    const sHash = await hashPassword(tempKey);
    const tel = (phone || req.body.mobile || '').trim() || null;

    let sId = schoolId;
    let sName = school_name;

    if (sId && !sName) {
      const school = await prisma.school.findUnique({ where: { id: sId } });
      if (school) sName = school.name;
    }

    const teacher = await prisma.teacher.create({
      data: {
        teacher_name: name,
        email: emailNorm,
        password_hash: pHash,
        staff_key_hash: sHash,
        subject: subject || null,
        phone: tel,
        schoolId: sId || 'school_001',
        school_name: sName || 'Unknown School',
        assigned_classes: assigned_classes || null,
      },
      select: SAFE_SELECT,
    });

    // Return credentials once — caller must store them
    res.status(201).json({ ...teacher, tempPassword, tempKey });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'Teacher with this email already exists' });
    }
    res.status(500).json({ error: 'Failed to create teacher.' });
  }
});

// PUT /api/v1/teachers/:id
router.put('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    // Whitelist updatable fields — prevent mass-assignment of hashes or IDs
    const { teacher_name, subject, phone, school_name, assigned_classes, status } = req.body;
    const updateData = { updated_at: new Date() };
    if (teacher_name) updateData.teacher_name = teacher_name.trim();
    if (subject !== undefined) updateData.subject = subject;
    if (phone !== undefined) updateData.phone = phone;
    if (school_name) updateData.school_name = school_name.trim();
    if (assigned_classes !== undefined) updateData.assigned_classes = assigned_classes;
    if (status) updateData.status = status;

    const teacher = await prisma.teacher.update({
      where: { id: req.params.id },
      data: updateData,
      select: SAFE_SELECT,
    });
    res.json(teacher);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Teacher not found.' });
    res.status(500).json({ error: 'Failed to update teacher.' });
  }
});

// DELETE /api/v1/teachers/:id
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await prisma.teacher.delete({ where: { id: req.params.id } });
    res.json({ message: 'Teacher removed successfully' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Teacher not found.' });
    res.status(500).json({ error: 'Failed to delete teacher.' });
  }
});

module.exports = router;

const express = require('express');
const prisma = require('../lib/prisma');
const { authenticate, authorize } = require('../middleware/auth');
const router = express.Router();

// GET /api/v1/students
router.get('/', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    const { search, schoolId } = req.query;
    const where = {};

    // Principals/teachers only see their own school's students
    if (req.user.role === 'principal' || req.user.role === 'teacher') {
      if (req.user.school_id) where.schoolId = req.user.school_id;
    } else if (schoolId) {
      where.schoolId = schoolId;
    }

    if (search) {
      where.OR = [
        { name: { contains: search } },
        { class_level: { contains: search } },
      ];
    }

    const students = await prisma.student.findMany({
      where,
      orderBy: { created_at: 'desc' },
    });

    res.json(students);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch students.' });
  }
});

// GET /api/v1/students/:id
router.get('/:id', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    const student = await prisma.student.findUnique({
      where: { id: req.params.id },
    });

    if (!student) return res.status(404).json({ error: 'Student not found' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch student.' });
  }
});

// POST /api/v1/students
router.post('/', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    const { name, email, phone, class_level, school_name, parent_name, parent_phone, schoolId } = req.body;

    if (!name || !email) {
      return res.status(400).json({ error: 'name and email are required.' });
    }

    const emailNorm = email.toLowerCase().trim();

    const student = await prisma.student.create({
      data: {
        name: name.trim(),
        email: emailNorm,
        phone: phone || null,
        class_level: class_level || null,
        school_name: school_name || null,
        parent_name: parent_name || null,
        parent_phone: parent_phone || null,
        schoolId: schoolId || null,
      },
    });

    res.status(201).json(student);
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'Student with this email already exists' });
    }
    res.status(500).json({ error: 'Failed to create student.' });
  }
});

// PUT /api/v1/students/:id — whitelist updatable fields
router.put('/:id', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    const { name, phone, class_level, class_name, school_name, parent_name, parent_phone, status } = req.body;
    const updateData = { updated_at: new Date() };
    if (name) updateData.name = name.trim();
    if (phone !== undefined) updateData.phone = phone;
    if (class_level !== undefined) updateData.class_level = class_level;
    if (class_name !== undefined) updateData.class_name = class_name;
    if (school_name) updateData.school_name = school_name;
    if (parent_name !== undefined) updateData.parent_name = parent_name;
    if (parent_phone !== undefined) updateData.parent_phone = parent_phone;
    if (status) updateData.status = status;

    const student = await prisma.student.update({
      where: { id: req.params.id },
      data: updateData,
    });
    res.json(student);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Student not found.' });
    res.status(500).json({ error: 'Failed to update student.' });
  }
});

// DELETE /api/v1/students/:id
router.delete('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    await prisma.student.delete({ where: { id: req.params.id } });
    res.json({ message: 'Student deleted successfully' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Student not found.' });
    res.status(500).json({ error: 'Failed to delete student.' });
  }
});

module.exports = router;

const express = require('express');
const prisma = require('../lib/prisma');
const { authenticate, authorize } = require('../middleware/auth');
const router = express.Router();

// GET /api/v1/live-classes — require auth
router.get('/', authenticate, async (req, res) => {
  try {
    const classes = await prisma.teacher_class_sessions.findMany({
      orderBy: { start_time: 'desc' },
    });
    res.json(classes);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch live classes.' });
  }
});

// POST /api/v1/live-classes
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { teacher_id, title, class_level, subject, start_time, end_time, room, mode, status } = req.body;

    if (!title || !class_level || !start_time) {
      return res.status(400).json({ error: 'title, class_level, and start_time are required.' });
    }

    const session = await prisma.teacher_class_sessions.create({
      data: {
        id: require('crypto').randomUUID(),
        teacher_id: teacher_id || req.user.id,
        title: title.trim(),
        class_level,
        subject: subject || null,
        start_time: new Date(start_time),
        end_time: end_time ? new Date(end_time) : null,
        room: room || null,
        mode: mode || 'online',
        status: status || 'scheduled',
      },
    });

    res.status(201).json(session);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create live class.' });
  }
});

// PUT /api/v1/live-classes/:id — whitelist fields
router.put('/:id', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { title, class_level, subject, start_time, end_time, room, mode, status } = req.body;
    const updateData = { updated_at: new Date() };
    if (title) updateData.title = title.trim();
    if (class_level) updateData.class_level = class_level;
    if (subject !== undefined) updateData.subject = subject;
    if (start_time) updateData.start_time = new Date(start_time);
    if (end_time) updateData.end_time = new Date(end_time);
    if (room !== undefined) updateData.room = room;
    if (mode) updateData.mode = mode;
    if (status) updateData.status = status;

    const session = await prisma.teacher_class_sessions.update({
      where: { id: req.params.id },
      data: updateData,
    });
    res.json(session);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Class session not found.' });
    res.status(500).json({ error: 'Failed to update live class.' });
  }
});

// DELETE /api/v1/live-classes/:id
router.delete('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    await prisma.teacher_class_sessions.delete({ where: { id: req.params.id } });
    res.json({ message: 'Live class removed' });
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Class session not found.' });
    res.status(500).json({ error: 'Failed to delete live class.' });
  }
});

module.exports = router;

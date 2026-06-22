const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse, sendPaginatedResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');

const router = express.Router();

// GET /api/v1/classes
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, teacher_id, class_level, status, mode } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (teacher_id) where.teacher_id = teacher_id;
    if (class_level) where.class_level = class_level;
    if (status) where.status = status;
    if (mode) where.mode = mode;

    if (req.user.role === 'teacher') {
      where.teacher_id = req.user.id;
    }

    const [classes, total] = await Promise.all([
      prisma.teacher_class_sessions.findMany({ where, skip, take: parseInt(limit), orderBy: { start_time: 'desc' } }),
      prisma.teacher_class_sessions.count({ where }),
    ]);

    sendPaginatedResponse(res, classes, total, page, limit);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch classes.');
  }
});

// GET /api/v1/classes/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const session = await prisma.teacher_class_sessions.findUnique({ where: { id: req.params.id } });
    if (!session) return sendResponse(res, 404, false, 'Class session not found.');
    sendResponse(res, 200, true, 'Class session fetched.', session);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch class session.');
  }
});

// POST /api/v1/classes
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), validateBody('title', 'class_level', 'start_time'), async (req, res) => {
  try {
    const { title, class_level, subject, start_time, end_time, room, mode, teacher_id } = req.body;

    const session = await prisma.teacher_class_sessions.create({
      data: {
        id: crypto.randomUUID(),
        teacher_id: teacher_id || req.user.id,
        title, class_level,
        subject: subject || null,
        start_time: new Date(start_time),
        end_time: end_time ? new Date(end_time) : null,
        room: room || null,
        mode: mode || 'online',
        status: 'scheduled',
      },
    });

    sendResponse(res, 201, true, 'Class session created.', session);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to create class session.');
  }
});

// PUT /api/v1/classes/:id
router.put('/:id', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { title, class_level, subject, start_time, end_time, room, mode, status } = req.body;
    const updateData = { updated_at: new Date() };
    if (title) updateData.title = title;
    if (class_level) updateData.class_level = class_level;
    if (subject) updateData.subject = subject;
    if (start_time) updateData.start_time = new Date(start_time);
    if (end_time) updateData.end_time = new Date(end_time);
    if (room) updateData.room = room;
    if (mode) updateData.mode = mode;
    if (status) updateData.status = status;

    const session = await prisma.teacher_class_sessions.update({ where: { id: req.params.id }, data: updateData });
    sendResponse(res, 200, true, 'Class session updated.', session);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to update class session.');
  }
});

// DELETE /api/v1/classes/:id
router.delete('/:id', authenticate, authorize('admin', 'principal'), async (req, res) => {
  try {
    await prisma.teacher_class_sessions.delete({ where: { id: req.params.id } });
    sendResponse(res, 200, true, 'Class session deleted.');
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to delete class session.');
  }
});

module.exports = router;

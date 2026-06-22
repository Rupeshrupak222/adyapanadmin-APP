const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse, sendPaginatedResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');

const router = express.Router();

// GET /api/v1/attendance
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, user_id, subject, status } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const where = {};

    if (req.user.role === 'student') {
      where.user_id = req.user.id;
    } else if (user_id) {
      where.user_id = user_id;
    }

    if (subject) where.subject = subject;
    if (status) where.status = status;

    const [records, total] = await Promise.all([
      prisma.attendance.findMany({ where, skip, take: parseInt(limit), orderBy: { created_at: 'desc' } }),
      prisma.attendance.count({ where }),
    ]);

    sendPaginatedResponse(res, records, total, page, limit);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch attendance.');
  }
});

// POST /api/v1/attendance
router.post('/', authenticate, authorize('teacher', 'admin', 'principal'), validateBody('user_id', 'subject', 'status'), async (req, res) => {
  try {
    const { user_id, subject, status, time, source } = req.body;
    const record = await prisma.attendance.create({
      data: {
        id: crypto.randomUUID(),
        user_id, subject, status,
        time: time || new Date().toISOString(),
        source: source || 'manual',
      },
    });
    sendResponse(res, 201, true, 'Attendance marked.', record);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to mark attendance.');
  }
});

// POST /api/v1/attendance/bulk
router.post('/bulk', authenticate, authorize('teacher', 'admin', 'principal'), async (req, res) => {
  try {
    const { records } = req.body;
    if (!Array.isArray(records) || records.length === 0) {
      return sendResponse(res, 400, false, 'Records must be a non-empty array.');
    }

    const data = records.map((r) => ({
      id: crypto.randomUUID(),
      user_id: r.user_id, subject: r.subject, status: r.status,
      time: r.time || new Date().toISOString(),
      source: r.source || 'bulk',
    }));

    const result = await prisma.attendance.createMany({ data });
    sendResponse(res, 201, true, `Attendance marked for ${result.count} students.`, { count: result.count });
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to mark bulk attendance.');
  }
});

// GET /api/v1/attendance/summary/:userId
router.get('/summary/:userId', authenticate, async (req, res) => {
  try {
    const { userId } = req.params;
    if (req.user.role === 'student' && req.user.id !== userId) {
      return sendResponse(res, 403, false, 'Access denied.');
    }

    const records = await prisma.attendance.findMany({ where: { user_id: userId } });
    const summary = {
      total: records.length,
      present: records.filter((r) => r.status === 'present').length,
      absent: records.filter((r) => r.status === 'absent').length,
      late: records.filter((r) => r.status === 'late').length,
    };
    summary.percentage = summary.total > 0 ? Math.round((summary.present / summary.total) * 100) : 0;

    sendResponse(res, 200, true, 'Attendance summary fetched.', summary);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch attendance summary.');
  }
});

module.exports = router;

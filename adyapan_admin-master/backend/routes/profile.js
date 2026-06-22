const express = require('express');
const prisma = require('../lib/prisma');
const { sendResponse } = require('../utils/response');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/profile
router.get('/', authenticate, async (req, res) => {
  try {
    const { id, role } = req.user;

    // Principal profile from principals table
    if (role === 'principal') {
      const principal = await prisma.principals.findUnique({
        where: { id },
      });
      if (principal) {
        return sendResponse(res, 200, true, 'Profile fetched.', {
          id: principal.id,
          name: principal.principal_name,
          email: principal.email,
          role: 'principal',
          phone: principal.phone || null,
          school_name: principal.school_name || null,
          school_id: principal.school_id || null,
          status: principal.status,
          created_at: principal.created_at,
          updated_at: principal.updated_at,
        });
      }
      // Fallback to users table
    }

    // Teacher profile from teachers table
    if (role === 'teacher') {
      const teacher = await prisma.teacher.findUnique({
        where: { id },
      });
      if (teacher) {
        return sendResponse(res, 200, true, 'Profile fetched.', {
          id: teacher.id,
          name: teacher.teacher_name,
          email: teacher.email,
          role: 'teacher',
          phone: teacher.phone || null,
          school_name: teacher.school_name || null,
          school_id: teacher.schoolId || null,
          subject: teacher.subject || null,
          status: teacher.status,
          created_at: teacher.created_at,
          updated_at: teacher.updated_at,
        });
      }
      // Fallback to users table
    }

    // Default: admin, student, or fallback
    const user = await prisma.users.findUnique({
      where: { id },
      select: {
        id: true, name: true, email: true, role: true, phone: true,
        class_level: true, class_name: true, school_name: true,
        school_id: true, signup_source: true, otp_verified: true,
        created_at: true, updated_at: true,
      },
    });

    if (!user) return sendResponse(res, 404, false, 'Profile not found.');
    sendResponse(res, 200, true, 'Profile fetched.', user);
  } catch (error) {
    console.error('Profile fetch error:', error);
    sendResponse(res, 500, false, 'Failed to fetch profile.');
  }
});

// PUT /api/v1/profile
router.put('/', authenticate, async (req, res) => {
  try {
    const { id, role } = req.user;
    const { name, phone, class_level, class_name, school_name } = req.body;

    // Principal profile update
    if (role === 'principal') {
      const principal = await prisma.principals.findUnique({ where: { id } });
      if (principal) {
        const updateData = { updated_at: new Date() };
        if (name) updateData.principal_name = name;
        if (phone) updateData.phone = phone;

        const updated = await prisma.principals.update({
          where: { id },
          data: updateData,
        });
        return sendResponse(res, 200, true, 'Profile updated.', {
          id: updated.id,
          name: updated.principal_name,
          email: updated.email,
          role: 'principal',
          phone: updated.phone || null,
          school_name: updated.school_name || null,
          school_id: updated.school_id || null,
        });
      }
    }

    // Teacher profile update
    if (role === 'teacher') {
      const teacher = await prisma.teacher.findUnique({ where: { id } });
      if (teacher) {
        const updateData = { updated_at: new Date() };
        if (name) updateData.teacher_name = name;
        if (phone) updateData.phone = phone;

        const updated = await prisma.teacher.update({
          where: { id },
          data: updateData,
        });
        return sendResponse(res, 200, true, 'Profile updated.', {
          id: updated.id,
          name: updated.teacher_name,
          email: updated.email,
          role: 'teacher',
          phone: updated.phone || null,
          school_name: updated.school_name || null,
          school_id: updated.schoolId || null,
          subject: updated.subject || null,
        });
      }
    }

    // Default: admin, student, or fallback
    const updateData = { updated_at: new Date() };
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (class_level) updateData.class_level = class_level;
    if (class_name) updateData.class_name = class_name;
    if (school_name) updateData.school_name = school_name;

    const user = await prisma.users.update({
      where: { id },
      data: updateData,
      select: { id: true, name: true, email: true, role: true, phone: true, class_level: true, class_name: true, school_name: true, updated_at: true },
    });

    sendResponse(res, 200, true, 'Profile updated.', user);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to update profile.');
  }
});

module.exports = router;

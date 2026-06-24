const express = require('express');
const prisma = require('../lib/prisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/dashboard — role-specific dashboard
router.get('/', authenticate, async (req, res) => {
  try {
    const { role, id, email } = req.user;
    let data = {};

    switch (role) {
      case 'student': data = await getStudentDashboard(id, email); break;
      case 'teacher': data = await getTeacherDashboard(id, email); break;
      case 'principal': data = await getPrincipalDashboard(id); break;
      case 'admin': data = await getAdminDashboard(); break;
      default: return sendResponse(res, 400, false, 'Unknown role.');
    }

    sendResponse(res, 200, true, `${role} dashboard fetched.`, data);
  } catch (error) {
    console.error('Dashboard error:', error);
    sendResponse(res, 500, false, 'Failed to fetch dashboard.');
  }
});

// GET /api/v1/dashboard/admin
router.get('/admin', authenticate, authorize('admin'), async (req, res) => {
  try {
    sendResponse(res, 200, true, 'Admin dashboard fetched.', await getAdminDashboard());
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch admin dashboard.');
  }
});

// GET /api/v1/dashboard/principal
router.get('/principal', authenticate, authorize('principal'), async (req, res) => {
  try {
    sendResponse(res, 200, true, 'Principal dashboard fetched.', await getPrincipalDashboard(req.user.id));
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to fetch principal dashboard.');
  }
});

async function getStudentDashboard(userId, email) {
  const [attendance, payments, notices, enrollments] = await Promise.all([
    prisma.attendance.findMany({ where: { user_id: userId }, orderBy: { created_at: 'desc' }, take: 10 }),
    prisma.payments.findMany({ where: { user_email: email }, orderBy: { created_at: 'desc' }, take: 5 }),
    prisma.notifications.findMany({ where: { OR: [{ user_email: email }, { user_email: null }] }, orderBy: { created_at: 'desc' }, take: 5 }),
    prisma.enrollments.findMany({ where: { user_email: email }, orderBy: { enrolled_at: 'desc' }, take: 5 }),
  ]);

  const totalAtt = await prisma.attendance.count({ where: { user_id: userId } });
  const presentCount = await prisma.attendance.count({ where: { user_id: userId, status: 'present' } });

  return {
    attendancePercentage: totalAtt > 0 ? Math.round((presentCount / totalAtt) * 100) : 0,
    recentAttendance: attendance,
    recentPayments: payments,
    notices,
    enrollments,
  };
}

async function getTeacherDashboard(userId, email) {
  // Try users table first, then teachers table for school context
  let schoolId = null;
  let teacherId = userId;

  const user = await prisma.users.findUnique({ where: { id: userId } });
  if (user) {
    schoolId = user.school_id;
    teacherId = user.teacher_id || userId;
  } else {
    const teacher = await prisma.teacher.findUnique({ where: { id: userId } });
    if (teacher) {
      schoolId = teacher.schoolId;
      teacherId = teacher.id;
    }
  }

  const [upcomingClasses, notices, totalStudents] = await Promise.all([
    prisma.teacher_class_sessions.findMany({
      where: { teacher_id: teacherId, start_time: { gte: new Date() } },
      orderBy: { start_time: 'asc' }, take: 10,
    }),
    prisma.notifications.findMany({ where: { OR: [{ user_email: email }, { user_email: null }] }, orderBy: { created_at: 'desc' }, take: 5 }),
    prisma.student.count({ where: schoolId ? { schoolId } : {} }),
  ]);
  return { totalStudents, upcomingClasses, notices };
}

async function getPrincipalDashboard(userId) {
  // Try users table first, then principals table for school context
  let schoolId = null;

  const user = await prisma.users.findUnique({ where: { id: userId } });
  if (user) {
    schoolId = user.school_id;
  } else {
    const principal = await prisma.principals.findUnique({ where: { id: userId } });
    if (principal) {
      schoolId = principal.school_id;
    }
  }

  const where = schoolId ? { schoolId } : {};

  const [totalStudents, totalTeachers, recentLogins] = await Promise.all([
    prisma.student.count({ where }),
    prisma.teacher.count({ where }),
    prisma.login_events.findMany({ orderBy: { created_at: 'desc' }, take: 10 }),
  ]);
  return { totalStudents, totalTeachers, recentLogins, schoolId };
}

async function getAdminDashboard() {
  const [totalUsers, totalStudents, totalTeachers, totalSchools, totalPayments, totalPrincipals, recentLogins] = await Promise.all([
    prisma.users.count(),
    prisma.student.count(),
    prisma.teacher.count(),
    prisma.school.count(),
    prisma.payments.count(),
    prisma.principals.count(),
    prisma.login_events.findMany({ orderBy: { created_at: 'desc' }, take: 10 }),
  ]);
  const paidPayments = await prisma.payments.count({ where: { status: 'paid' } });
  return { totalUsers, totalStudents, totalTeachers, totalSchools, totalPrincipals, totalPayments, paidPayments, recentLogins };
}

module.exports = router;

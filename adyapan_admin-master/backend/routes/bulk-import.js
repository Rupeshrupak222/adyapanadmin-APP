const express = require('express');
const crypto = require('crypto');
const multer = require('multer');
const csv = require('csv-parser');
const { Readable } = require('stream');
const prisma = require('../lib/prisma');
const { hashPassword } = require('../utils/password');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Multer config — accept CSV files up to 5MB
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'text/csv' || file.originalname.endsWith('.csv')) {
      cb(null, true);
    } else {
      cb(new Error('Only CSV files are allowed'));
    }
  },
});

/**
 * Generate readable temporary password
 * Format: ADY-{6 random alphanumeric}-{year}
 */
function generateTempPassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[crypto.randomInt(chars.length)];
  }
  return `ADY-${code}-${new Date().getFullYear()}`;
}

/**
 * Generate staff/access key
 * Format: KEY-{8 random alphanumeric}
 */
function generateKey() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[crypto.randomInt(chars.length)];
  }
  return `KEY-${code}`;
}

/**
 * Parse CSV buffer into array of objects
 */
function parseCSV(buffer) {
  return new Promise((resolve, reject) => {
    const results = [];
    const stream = Readable.from(buffer.toString('utf8'));
    stream
      .pipe(csv({ mapHeaders: ({ header }) => header.trim().toLowerCase().replace(/\s+/g, '_') }))
      .on('data', (row) => results.push(row))
      .on('end', () => resolve(results))
      .on('error', reject);
  });
}

// ─── POST /api/v1/bulk-import/teachers ──────────────────────────────
// Upload CSV with columns: name, email, subject, phone, school_name
// Admin/Principal only
router.post(
  '/teachers',
  authenticate,
  authorize('admin', 'principal'),
  upload.single('file'),
  async (req, res) => {
    try {
      if (!req.file) {
        return sendResponse(res, 400, false, 'CSV file is required. Upload with field name "file".');
      }

      const rows = await parseCSV(req.file.buffer);

      if (rows.length === 0) {
        return sendResponse(res, 400, false, 'CSV file is empty.');
      }

      if (rows.length > 500) {
        return sendResponse(res, 400, false, 'Maximum 500 teachers per upload.');
      }

      // Validate required columns
      const requiredCols = ['name', 'email'];
      const headers = Object.keys(rows[0]);
      const missingCols = requiredCols.filter((col) => !headers.includes(col));
      if (missingCols.length > 0) {
        return sendResponse(res, 400, false, `Missing required columns: ${missingCols.join(', ')}. Found: ${headers.join(', ')}`);
      }

      const schoolId = req.body.school_id || req.user.school_id || 'school_001';
      const schoolName = req.body.school_name || 'Adyapan School';

      const results = { created: [], skipped: [], errors: [] };

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const rowNum = i + 2; // +2 because row 1 is header

        try {
          const email = (row.email || '').trim().toLowerCase();
          const name = (row.name || row.teacher_name || '').trim();

          if (!email || !name) {
            results.errors.push({ row: rowNum, reason: 'Missing name or email' });
            continue;
          }

          if (!/^[a-z0-9][a-z0-9._-]*@[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/.test(email)) {
            results.errors.push({ row: rowNum, email, reason: 'Invalid email format' });
            continue;
          }

          // Check if already exists
          const existing = await prisma.teacher.findUnique({ where: { email } });
          if (existing) {
            results.skipped.push({ row: rowNum, email, reason: 'Already exists' });
            continue;
          }

          // Generate credentials
          const tempPassword = generateTempPassword();
          const staffKey = generateKey();
          const passwordHash = await hashPassword(tempPassword);
          const staffKeyHash = await hashPassword(staffKey);

          await prisma.teacher.create({
            data: {
              schoolId,
              school_name: row.school_name || schoolName,
              teacher_name: name,
              email,
              password_hash: passwordHash,
              staff_key_hash: staffKeyHash,
              subject: row.subject || null,
              phone: row.phone || null,
              assigned_classes: row.classes ? JSON.parse(`[${row.classes.split(';').map((c) => `"${c.trim()}"`).join(',')}]`) : null,
              status: 'active',
            },
          });

          results.created.push({
            row: rowNum,
            name,
            email,
            tempPassword,
            staffKey,
            subject: row.subject || null,
          });
        } catch (err) {
          results.errors.push({ row: rowNum, email: row.email, reason: err.message });
        }
      }

      sendResponse(res, 200, true, `Import complete. Created: ${results.created.length}, Skipped: ${results.skipped.length}, Errors: ${results.errors.length}`, results);
    } catch (err) {
      console.error('Bulk import teachers error:', err.message);
      sendResponse(res, 500, false, 'Failed to process CSV file.');
    }
  }
);

// ─── POST /api/v1/bulk-import/principals ────────────────────────────
// Upload CSV with columns: name, email, school_name, phone
// Admin only
router.post(
  '/principals',
  authenticate,
  authorize('admin'),
  upload.single('file'),
  async (req, res) => {
    try {
      if (!req.file) {
        return sendResponse(res, 400, false, 'CSV file is required.');
      }

      const rows = await parseCSV(req.file.buffer);

      if (rows.length === 0) return sendResponse(res, 400, false, 'CSV file is empty.');
      if (rows.length > 200) return sendResponse(res, 400, false, 'Maximum 200 principals per upload.');

      const requiredCols = ['name', 'email', 'school_name'];
      const headers = Object.keys(rows[0]);
      const missingCols = requiredCols.filter((col) => !headers.includes(col));
      if (missingCols.length > 0) {
        return sendResponse(res, 400, false, `Missing required columns: ${missingCols.join(', ')}`);
      }

      const results = { created: [], skipped: [], errors: [] };

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const rowNum = i + 2;

        try {
          const email = (row.email || '').trim().toLowerCase();
          const name = (row.name || row.principal_name || '').trim();
          const schoolName = (row.school_name || '').trim();

          if (!email || !name || !schoolName) {
            results.errors.push({ row: rowNum, reason: 'Missing name, email, or school_name' });
            continue;
          }

          if (!/^[a-z0-9][a-z0-9._-]*@[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/.test(email)) {
            results.errors.push({ row: rowNum, email, reason: 'Invalid email format' });
            continue;
          }

          const existing = await prisma.principals.findUnique({ where: { email } });
          if (existing) {
            results.skipped.push({ row: rowNum, email, reason: 'Already exists' });
            continue;
          }

          const tempPassword = generateTempPassword();
          const accessKey = generateKey();
          const passwordHash = await hashPassword(tempPassword);
          const accessKeyHash = await hashPassword(accessKey);

          // Find or create school
          let schoolId = 'school_' + crypto.randomUUID().slice(0, 8);
          const schools = await prisma.school.findMany({ where: { name: { contains: schoolName } }, take: 1 });
          if (schools.length > 0) {
            schoolId = schools[0].id;
          }

          await prisma.principals.create({
            data: {
              id: crypto.randomUUID().replace(/-/g, '').slice(0, 25),
              school_id: schoolId,
              school_name: schoolName,
              principal_name: name,
              email,
              password_hash: passwordHash,
              access_key_hash: accessKeyHash,
              phone: row.phone || null,
              status: 'active',
            },
          });

          results.created.push({
            row: rowNum,
            name,
            email,
            schoolName,
            tempPassword,
            accessKey,
          });
        } catch (err) {
          results.errors.push({ row: rowNum, email: row.email, reason: err.message });
        }
      }

      sendResponse(res, 200, true, `Import complete. Created: ${results.created.length}, Skipped: ${results.skipped.length}, Errors: ${results.errors.length}`, results);
    } catch (err) {
      console.error('Bulk import principals error:', err.message);
      sendResponse(res, 500, false, 'Failed to process CSV file.');
    }
  }
);

// ─── POST /api/v1/bulk-import/students ──────────────────────────────
// Upload CSV with columns: name, email, phone, class_level, school_name
router.post(
  '/students',
  authenticate,
  authorize('admin', 'principal'),
  upload.single('file'),
  async (req, res) => {
    try {
      if (!req.file) return sendResponse(res, 400, false, 'CSV file is required.');

      const rows = await parseCSV(req.file.buffer);
      if (rows.length === 0) return sendResponse(res, 400, false, 'CSV file is empty.');
      if (rows.length > 1000) return sendResponse(res, 400, false, 'Maximum 1000 students per upload.');

      const requiredCols = ['name', 'email'];
      const headers = Object.keys(rows[0]);
      const missingCols = requiredCols.filter((col) => !headers.includes(col));
      if (missingCols.length > 0) {
        return sendResponse(res, 400, false, `Missing required columns: ${missingCols.join(', ')}`);
      }

      const results = { created: [], skipped: [], errors: [] };

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const rowNum = i + 2;

        try {
          const email = (row.email || '').trim().toLowerCase();
          const name = (row.name || '').trim();

          if (!email || !name) {
            results.errors.push({ row: rowNum, reason: 'Missing name or email' });
            continue;
          }

          const existing = await prisma.student.findUnique({ where: { email } });
          if (existing) {
            results.skipped.push({ row: rowNum, email, reason: 'Already exists' });
            continue;
          }

          const tempPassword = generateTempPassword();
          const passwordHash = await hashPassword(tempPassword);

          // Create user account
          const userId = crypto.randomUUID().replace(/-/g, '').slice(0, 25);
          await prisma.users.create({
            data: {
              id: userId,
              name,
              email,
              password_hash: passwordHash,
              password: passwordHash,
              phone: row.phone || null,
              role: 'student',
              class_level: row.class_level || row.class || null,
              class_name: row.class_level || row.class || null,
              school_name: row.school_name || null,
              signup_source: 'bulk_import',
            },
          });

          // Create student record
          await prisma.student.create({
            data: {
              user_id: userId,
              name,
              email,
              phone: row.phone || null,
              class_level: row.class_level || row.class || null,
              school_name: row.school_name || null,
              parent_name: row.parent_name || null,
              parent_phone: row.parent_phone || null,
              signup_source: 'bulk_import',
            },
          });

          results.created.push({ row: rowNum, name, email, tempPassword });
        } catch (err) {
          if (err.code === 'P2002') {
            results.skipped.push({ row: rowNum, email: row.email, reason: 'Duplicate email' });
          } else {
            results.errors.push({ row: rowNum, email: row.email, reason: err.message });
          }
        }
      }

      sendResponse(res, 200, true, `Import complete. Created: ${results.created.length}, Skipped: ${results.skipped.length}, Errors: ${results.errors.length}`, results);
    } catch (err) {
      console.error('Bulk import students error:', err.message);
      sendResponse(res, 500, false, 'Failed to process CSV file.');
    }
  }
);

// ─── GET /api/v1/bulk-import/template/:type ─────────────────────────
// Download CSV template
router.get('/template/:type', authenticate, (req, res) => {
  const templates = {
    teachers: 'name,email,subject,phone,school_name,classes\nRahul Sharma,rahul@school.com,Mathematics,9876543210,DPS School,Class 5;Class 6\nPriya Singh,priya@school.com,Science,9876543211,DPS School,Class 7',
    principals: 'name,email,school_name,phone\nDr. Verma,verma@dps.com,DPS School,9876543210\nMrs. Gupta,gupta@kvs.com,KV School,9876543211',
    students: 'name,email,phone,class_level,school_name,parent_name,parent_phone\nAman Kumar,aman@gmail.com,9876543210,Class 5,DPS School,Rajesh Kumar,9876543200\nNeha Patel,neha@gmail.com,9876543211,Class 6,DPS School,Suresh Patel,9876543201',
  };

  const type = req.params.type;
  if (!templates[type]) {
    return sendResponse(res, 400, false, 'Invalid template type. Use: teachers, principals, students');
  }

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename=${type}-template.csv`);
  res.send(templates[type]);
});

module.exports = router;

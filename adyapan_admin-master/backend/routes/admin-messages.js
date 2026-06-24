/**
 * admin-messages.js
 *
 * Unified messaging backend — shared by the Flutter admin app AND the
 * Adyapan website (preschool-wzjj.onrender.com).
 *
 * Both projects write to / read from the same `admin_messages` table so
 * a message sent from the website immediately appears in the Flutter app
 * and vice versa.
 *
 * Table schema (auto-created if absent):
 *   admin_messages (
 *     id             VARCHAR(64)   PRIMARY KEY,
 *     sender_email   VARCHAR(190)  NOT NULL,
 *     sender_name    VARCHAR(190)  NOT NULL,
 *     recipient_type ENUM('individual','broadcast') NOT NULL,
 *     recipient_email VARCHAR(190) NULL,   -- set for individual
 *     recipient_role  VARCHAR(40)  NULL,   -- set for broadcast
 *     message        TEXT          NOT NULL,
 *     is_read        TINYINT(1)    NOT NULL DEFAULT 0,
 *     created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
 *   )
 */

const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// ─── Ensure admin_messages table exists ──────────────────────────────────────
// Runs lazily on first request so it works without a manual migration.
let _tableReady = false;
async function ensureTable() {
  if (_tableReady) return;
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS admin_messages (
      id              VARCHAR(64)   NOT NULL PRIMARY KEY,
      sender_email    VARCHAR(190)  NOT NULL,
      sender_name     VARCHAR(190)  NOT NULL DEFAULT '',
      recipient_type  VARCHAR(20)   NOT NULL DEFAULT 'individual',
      recipient_email VARCHAR(190)  NULL,
      recipient_role  VARCHAR(40)   NULL,
      message         TEXT          NOT NULL,
      is_read         TINYINT(1)    NOT NULL DEFAULT 0,
      created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
      parent_message_id VARCHAR(64) NULL,
      parent_message_text TEXT NULL,
      KEY idx_amsg_recipient_email (recipient_email),
      KEY idx_amsg_recipient_role  (recipient_role),
      KEY idx_amsg_created_at      (created_at)
    )
  `);
  // Dynamically add columns in case the table already existed
  try {
    await prisma.$executeRawUnsafe(`
      ALTER TABLE admin_messages ADD COLUMN parent_message_id VARCHAR(64) NULL
    `);
  } catch (_) {}
  try {
    await prisma.$executeRawUnsafe(`
      ALTER TABLE admin_messages ADD COLUMN parent_message_text TEXT NULL
    `);
  } catch (_) {}
  _tableReady = true;
}

// ─── FCM helper ──────────────────────────────────────────────────────────────
let _fcmApp = null;
function getFcmApp() {
  if (_fcmApp) return _fcmApp;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const admin = require('firebase-admin');
    const sa = typeof raw === 'string' ? JSON.parse(raw) : raw;
    _fcmApp = admin.initializeApp({ credential: admin.credential.cert(sa) }, 'adyapan-fcm');
    console.log('✅ Firebase Admin initialised for FCM');
    return _fcmApp;
  } catch (err) {
    console.error('⚠️  Firebase Admin init failed:', err.message);
    return null;
  }
}

async function sendFcm(token, title, body, data = {}) {
  if (!token) return;
  const app = getFcmApp();
  if (!app) return;
  try {
    const admin = require('firebase-admin');
    await admin.messaging(app).send({
      notification: { title, body },
      data: { sentAt: new Date().toISOString(), ...data },
      token,
      android: { priority: 'high', notification: { channelId: 'admin_messages', sound: 'default' } },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });
  } catch (err) {
    // Clear stale tokens
    if (['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(err.code)) {
      await prisma.principals.updateMany({ where: { fcm_token: token }, data: { fcm_token: null } }).catch(() => {});
      await prisma.teacher.updateMany({ where: { fcm_token: token }, data: { fcm_token: null } }).catch(() => {});
      await prisma.admin_fcm_tokens.deleteMany({ where: { fcm_token: token } }).catch(() => {});
    }
    console.error('FCM error:', err.message);
  }
}

async function notifyAdmins(title, body) {
  try {
    const tokens = await prisma.admin_fcm_tokens.findMany();
    await Promise.allSettled(tokens.map(t => sendFcm(t.fcm_token, title, body, { type: 'reply' })));
  } catch (err) {
    console.error('notifyAdmins error:', err.message);
  }
}

// ─── PATCH /fcm-token ─────────────────────────────────────────────────────────
// Register/refresh FCM token for admin, principal, or teacher after login.
router.patch('/fcm-token', authenticate, authorize('principal', 'teacher', 'admin'), async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) return sendResponse(res, 400, false, 'fcm_token is required.');
    const email = req.user?.email?.toLowerCase().trim();
    if (!email) return sendResponse(res, 401, false, 'Unauthorised.');

    if (req.user.role === 'admin') {
      await prisma.admin_fcm_tokens.upsert({
        where: { email },
        update: { fcm_token: fcm_token.trim(), updated_at: new Date() },
        create: { id: crypto.randomUUID(), email, fcm_token: fcm_token.trim(), updated_at: new Date() },
      });
    } else if (req.user.role === 'teacher') {
      await prisma.teacher.updateMany({ where: { email }, data: { fcm_token: fcm_token.trim() } });
    } else {
      await prisma.principals.updateMany({ where: { email }, data: { fcm_token: fcm_token.trim() } });
    }
    sendResponse(res, 200, true, 'FCM token updated.');
  } catch (err) {
    console.error('fcm-token error:', err);
    sendResponse(res, 500, false, 'Failed to update FCM token.');
  }
});

// ─── GET / ────────────────────────────────────────────────────────────────────
// Inbox for principal or teacher — messages addressed to them individually
// OR broadcast to their role.
router.get('/', authenticate, authorize('principal', 'teacher', 'admin'), async (req, res) => {
  try {
    await ensureTable();
    const email = req.user.email.toLowerCase().trim();
    const role = req.user.role;

    let rows;
    if (role === 'admin') {
      // Admin sees messages sent TO admin (broadcasts + individual)
      rows = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, recipient_type, recipient_role, message, is_read, created_at, parent_message_id, parent_message_text
         FROM admin_messages
         WHERE (recipient_type = 'individual' AND recipient_email = ?)
            OR (recipient_type = 'broadcast' AND recipient_role = 'admin')
         ORDER BY created_at DESC LIMIT 100`,
        email
      );
    } else {
      rows = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, recipient_type, recipient_role, message, is_read, created_at, parent_message_id, parent_message_text
         FROM admin_messages
         WHERE (recipient_type = 'individual' AND recipient_email = ?)
            OR (recipient_type = 'broadcast' AND recipient_role = ?)
         ORDER BY created_at DESC LIMIT 100`,
        email,
        role
      );
    }

    const formatted = (rows ?? []).map(r => ({
      id: String(r.id),
      title: r.recipient_role === 'admin'
        ? `📩 Reply from ${r.sender_name || r.sender_email}`
        : `📢 Message from ${r.sender_name || 'Admin'}`,
      message: String(r.message),
      sender_name: String(r.sender_name || ''),
      from_email: String(r.sender_email),
      sentAt: r.created_at,
      status: r.is_read ? 'read' : 'sent',
      read_at: r.is_read ? r.created_at : null,
      parent_message_id: r.parent_message_id ? String(r.parent_message_id) : null,
      parent_message_text: r.parent_message_text ? String(r.parent_message_text) : null,
    }));

    res.json(formatted);
  } catch (err) {
    console.error('GET admin-messages error:', err);
    sendResponse(res, 500, false, 'Failed to fetch messages.');
  }
});

// ─── POST / ───────────────────────────────────────────────────────────────────
// Admin sends a message to principals and/or teachers of selected schools.
// Body: { message, schoolIds[], sendToAll, targetRole: 'all'|'principal'|'teacher' }
router.post('/', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    await ensureTable();
    const { message, schoolIds, sendToAll, targetRole, recipient } = req.body;

    // Handle principal or teacher reply sent via the POST / endpoint
    if (req.user.role === 'principal' || req.user.role === 'teacher') {
      if (recipient !== 'all-admins') {
        return sendResponse(res, 403, false, 'Unauthorized to send to this recipient.');
      }
      
      const { parent_message_id, parent_message_text } = req.body;
      if (!message?.trim()) return sendResponse(res, 400, false, 'message is required.');

      const email = req.user.email.toLowerCase().trim();
      const role = req.user.role;
      let senderLabel = email;

      if (role === 'teacher') {
        const t = await prisma.teacher.findUnique({ where: { email } });
        if (t) senderLabel = `${t.teacher_name} – Teacher (${t.school_name})`;
      } else {
        const p = await prisma.principals.findUnique({ where: { email } });
        if (p) senderLabel = `${p.principal_name} – Principal (${p.school_name})`;
      }

      const id = crypto.randomUUID();
      await prisma.$executeRawUnsafe(
        `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_role, message, parent_message_id, parent_message_text)
         VALUES (?, ?, ?, 'broadcast', 'admin', ?, ?, ?)`,
        id, email, senderLabel, message.trim(), parent_message_id || null, parent_message_text || null
      );

      // Push notification to all admins
      notifyAdmins(`📩 Reply from ${senderLabel}`, message.trim());

      return sendResponse(res, 201, true, 'Reply sent to admin.', { id, message: message.trim(), sentAt: new Date() });
    }

    const role = targetRole || 'all';

    if (!message?.trim()) return sendResponse(res, 400, false, 'message is required.');

    const senderEmail = req.user.email.toLowerCase().trim();
    const senderName = req.user.name || 'Admin';
    const msgTrimmed = message.trim();
    const FCM_TITLE = '📢 Message from Admin';

    const insertMsg = async (recipientEmail, recipientRole, isBroadcast) => {
      const id = crypto.randomUUID();
      if (isBroadcast) {
        await prisma.$executeRawUnsafe(
          `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_role, message)
           VALUES (?, ?, ?, 'broadcast', ?, ?)`,
          id, senderEmail, senderName, recipientRole, msgTrimmed
        );
      } else {
        await prisma.$executeRawUnsafe(
          `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_email, recipient_role, message)
           VALUES (?, ?, ?, 'individual', ?, ?, ?)`,
          id, senderEmail, senderName, recipientEmail, recipientRole, msgTrimmed
        );
      }
    };

    if (sendToAll) {
      // Broadcast rows
      if (role === 'all' || role === 'principal') await insertMsg(null, 'principal', true);
      if (role === 'all' || role === 'teacher')   await insertMsg(null, 'teacher', true);

      // FCM to all with tokens
      const pushTargets = [];
      if (role === 'all' || role === 'principal') {
        const ps = await prisma.principals.findMany({ where: { fcm_token: { not: null }, status: 'active' }, select: { fcm_token: true } });
        ps.forEach(p => pushTargets.push(p.fcm_token));
      }
      if (role === 'all' || role === 'teacher') {
        const ts = await prisma.teacher.findMany({ where: { fcm_token: { not: null }, status: 'active' }, select: { fcm_token: true } });
        ts.forEach(t => pushTargets.push(t.fcm_token));
      }
      await Promise.allSettled(pushTargets.map(token => sendFcm(token, FCM_TITLE, msgTrimmed, { type: 'admin_message' })));

      return sendResponse(res, 201, true, 'Broadcast message sent.');
    }

    if (!Array.isArray(schoolIds) || schoolIds.length === 0) {
      return sendResponse(res, 400, false, 'No schoolIds provided.');
    }

    let principals = [], teachers = [];
    if (role === 'all' || role === 'principal') {
      principals = await prisma.principals.findMany({ where: { school_id: { in: schoolIds } } });
    }
    if (role === 'all' || role === 'teacher') {
      teachers = await prisma.teacher.findMany({ where: { schoolId: { in: schoolIds } } });
    }

    if (!principals.length && !teachers.length) {
      return sendResponse(res, 404, false, 'No recipients found for the selected schools.');
    }

    await Promise.all([
      ...principals.map(p => insertMsg(p.email?.toLowerCase().trim(), 'principal', false)),
      ...teachers.map(t => insertMsg(t.email?.toLowerCase().trim(), 'teacher', false)),
    ]);

    await Promise.allSettled([
      ...principals.filter(p => p.fcm_token).map(p => sendFcm(p.fcm_token, FCM_TITLE, msgTrimmed, { type: 'admin_message' })),
      ...teachers.filter(t => t.fcm_token).map(t => sendFcm(t.fcm_token, FCM_TITLE, msgTrimmed, { type: 'admin_message' })),
    ]);

    sendResponse(res, 201, true, `Message sent to ${principals.length + teachers.length} recipient(s).`);
  } catch (err) {
    console.error('POST admin-messages error:', err);
    sendResponse(res, 500, false, 'Failed to send message.');
  }
});

// ─── PUT /:id/read ────────────────────────────────────────────────────────────
router.put('/:id/read', authenticate, authorize('principal', 'teacher', 'admin'), async (req, res) => {
  try {
    await ensureTable();
    await prisma.$executeRawUnsafe(
      'UPDATE admin_messages SET is_read = 1 WHERE id = ?',
      req.params.id
    );
    sendResponse(res, 200, true, 'Message marked as read.');
  } catch (err) {
    console.error('mark-read error:', err);
    sendResponse(res, 500, false, 'Failed to mark as read.');
  }
});

// ─── POST /reply ──────────────────────────────────────────────────────────────
// Principal or Teacher sends a reply to admin.
// Stored as a broadcast to 'admin' role so ALL admin views pick it up.
router.post('/reply', authenticate, authorize('principal', 'teacher'), async (req, res) => {
  try {
    await ensureTable();
    const { message, parent_message_id, parent_message_text } = req.body;
    if (!message?.trim()) return sendResponse(res, 400, false, 'message is required.');

    const email = req.user.email.toLowerCase().trim();
    const role = req.user.role;
    let senderLabel = email;

    if (role === 'teacher') {
      const t = await prisma.teacher.findUnique({ where: { email } });
      if (t) senderLabel = `${t.teacher_name} – Teacher (${t.school_name})`;
    } else {
      const p = await prisma.principals.findUnique({ where: { email } });
      if (p) senderLabel = `${p.principal_name} – Principal (${p.school_name})`;
    }

    const id = crypto.randomUUID();
    await prisma.$executeRawUnsafe(
      `INSERT INTO admin_messages (id, sender_email, sender_name, recipient_type, recipient_role, message, parent_message_id, parent_message_text)
       VALUES (?, ?, ?, 'broadcast', 'admin', ?, ?, ?)`,
      id, email, senderLabel, message.trim(), parent_message_id || null, parent_message_text || null
    );

    // Push notification to all admins
    notifyAdmins(`📩 Reply from ${senderLabel}`, message.trim());

    sendResponse(res, 201, true, 'Reply sent to admin.', { id, message: message.trim(), sentAt: new Date() });
  } catch (err) {
    console.error('reply error:', err);
    sendResponse(res, 500, false, 'Failed to send reply.');
  }
});

// ─── GET /replies ─────────────────────────────────────────────────────────────
// Admin fetches all replies (messages addressed to 'admin' from principal/teacher).
router.get('/replies', authenticate, authorize('admin'), async (req, res) => {
  try {
    await ensureTable();
    const { schoolId, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    let rows;
    if (schoolId) {
      const principals = await prisma.principals.findMany({ where: { school_id: schoolId }, select: { email: true } });
      const teachers = await prisma.teacher.findMany({ where: { schoolId }, select: { email: true } });
      const emails = [
        ...principals.map(p => p.email.toLowerCase().trim()),
        ...teachers.map(t => t.email.toLowerCase().trim()),
      ];
      if (!emails.length) return res.json([]);
      const placeholders = emails.map(() => '?').join(',');
      rows = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, message, is_read, created_at, parent_message_id, parent_message_text
         FROM admin_messages
         WHERE recipient_type = 'broadcast' AND recipient_role = 'admin'
           AND sender_email IN (${placeholders})
         ORDER BY created_at DESC LIMIT ? OFFSET ?`,
        ...emails, parseInt(limit), skip
      );
    } else {
      rows = await prisma.$queryRawUnsafe(
        `SELECT id, sender_email, sender_name, message, is_read, created_at, parent_message_id, parent_message_text
         FROM admin_messages
         WHERE recipient_type = 'broadcast' AND recipient_role = 'admin'
         ORDER BY created_at DESC LIMIT ? OFFSET ?`,
        parseInt(limit), skip
      );
    }

    const formatted = (rows ?? []).map(r => ({
      id: String(r.id),
      title: `📩 Reply from ${r.sender_name || r.sender_email}`,
      message: String(r.message),
      from_email: String(r.sender_email),
      sender_name: String(r.sender_name || ''),
      sentAt: r.created_at,
      status: r.is_read ? 'read' : 'sent',
      parent_message_id: r.parent_message_id ? String(r.parent_message_id) : null,
      parent_message_text: r.parent_message_text ? String(r.parent_message_text) : null,
    }));

    res.json(formatted);
  } catch (err) {
    console.error('GET replies error:', err);
    sendResponse(res, 500, false, 'Failed to fetch replies.');
  }
});

// ─── DELETE /clear ────────────────────────────────────────────────────────────
// Truncates / deletes all messages and replies from the database.
router.delete('/clear', authenticate, authorize('admin', 'principal', 'teacher'), async (req, res) => {
  try {
    await ensureTable();
    await prisma.$executeRawUnsafe('DELETE FROM admin_messages');
    sendResponse(res, 200, true, 'All messages cleared.');
  } catch (err) {
    console.error('DELETE clear error:', err);
    sendResponse(res, 500, false, 'Failed to clear messages.');
  }
});

// ─── DELETE /:id ─────────────────────────────────────────────────────────────
// Delete a single message by ID (admin only).
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    await ensureTable();
    await prisma.$executeRawUnsafe(
      'DELETE FROM admin_messages WHERE id = ?',
      req.params.id
    );
    sendResponse(res, 200, true, 'Message deleted.');
  } catch (err) {
    console.error('delete message error:', err);
    sendResponse(res, 500, false, 'Failed to delete message.');
  }
});

// ─── DELETE /clear-replies ────────────────────────────────────────────────────
// Delete ALL reply messages sent to admin (admin only).
router.delete('/clear-replies', authenticate, authorize('admin'), async (req, res) => {
  try {
    await ensureTable();
    await prisma.$executeRawUnsafe(
      `DELETE FROM admin_messages WHERE recipient_type = 'broadcast' AND recipient_role = 'admin'`
    );
    sendResponse(res, 200, true, 'All replies cleared.');
  } catch (err) {
    console.error('clear-replies error:', err);
    sendResponse(res, 500, false, 'Failed to clear replies.');
  }
});

module.exports = router;

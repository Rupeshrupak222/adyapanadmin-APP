const express = require('express');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { sendResponse } = require('../utils/response');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// ─── FCM helper ─────────────────────────────────────────────────────────────
// Lazily initialise firebase-admin only when a valid service-account JSON is
// provided.  If it is absent the route still works – messages are saved to DB
// and principals see them on the next 30-second poll; no crash occurs.
let _fcmApp = null;

function getFcmApp() {
  if (_fcmApp) return _fcmApp;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;

  try {
    const admin = require('firebase-admin');
    const serviceAccount = typeof raw === 'string' ? JSON.parse(raw) : raw;

    _fcmApp = admin.initializeApp(
      { credential: admin.credential.cert(serviceAccount) },
      'adyapan-fcm'          // named app so it doesn't clash with other usages
    );
    console.log('✅ Firebase Admin initialised for FCM');
    return _fcmApp;
  } catch (err) {
    console.error('⚠️  Firebase Admin init failed – push notifications disabled:', err.message);
    return null;
  }
}

/**
 * Send a single FCM push notification.
 * Silently swallows errors so the main flow is never broken.
 *
 * @param {string} token  - FCM device token
 * @param {string} title  - notification title
 * @param {string} body   - notification body
 */
async function sendFcmPush(token, title, body) {
  if (!token) return;
  const app = getFcmApp();
  if (!app) return;

  try {
    const admin = require('firebase-admin');
    const message = {
      notification: { title, body },
      data: { type: 'admin_message', sentAt: new Date().toISOString() },
      token,
      android: {
        priority: 'high',
        notification: { channelId: 'admin_messages', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    };
    await admin.messaging(app).send(message);
  } catch (err) {
    // Invalid / expired token – clear it from DB to avoid future failures
    if (
      err.code === 'messaging/invalid-registration-token' ||
      err.code === 'messaging/registration-token-not-registered'
    ) {
      try {
        await prisma.principals.updateMany({
          where: { fcm_token: token },
          data: { fcm_token: null },
        });
      } catch (_) {}
    }
    console.error('FCM send error:', err.message);
  }
}

// ─── PATCH /api/v1/admin-messages/fcm-token ──────────────────────────────────
// Called by the Flutter app (Principal) after login to register / refresh the
// FCM device token so push notifications reach the device.
router.patch('/fcm-token', authenticate, authorize('principal', 'admin'), async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) {
      return sendResponse(res, 400, false, 'fcm_token is required.');
    }

    const email = req.user?.email?.toLowerCase().trim();
    if (!email) {
      return sendResponse(res, 401, false, 'Unauthorised.');
    }

    await prisma.principals.updateMany({
      where: { email },
      data: { fcm_token: fcm_token.trim() },
    });

    sendResponse(res, 200, true, 'FCM token updated.');
  } catch (error) {
    console.error('Failed to update FCM token:', error);
    sendResponse(res, 500, false, 'Failed to update FCM token.');
  }
});

// ─── GET /api/v1/admin-messages ──────────────────────────────────────────────
// Principals fetch their inbox; Admins can optionally query by schoolId.
router.get('/', authenticate, authorize('principal', 'admin'), async (req, res) => {
  try {
    const { schoolId } = req.query;
    let emails = [];

    if (req.user && req.user.email) {
      emails.push(req.user.email.toLowerCase().trim());
    }

    // Also resolve principal emails for the schoolId if provided
    if (schoolId) {
      const principals = await prisma.principals.findMany({
        where: {
          OR: [
            { id: schoolId },
            { school_id: schoolId },
            { school_name: schoolId },
          ],
        },
      });
      principals.forEach((p) => {
        if (p.email) {
          const email = p.email.toLowerCase().trim();
          if (!emails.includes(email)) emails.push(email);
        }
      });
    }

    const notices = await prisma.notifications.findMany({
      where: {
        OR: [
          { user_email: { in: emails } },
          { user_email: null },
        ],
      },
      orderBy: { created_at: 'desc' },
    });

    // Format to what client expects: id, title, message, sentAt, status
    const formatted = notices.map((n) => ({
      id: n.id,
      title: n.title || '📢 Admin Message',
      message: n.message,
      sentAt: n.created_at,
      status: n.status,
      read_at: n.read_at,
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Failed to fetch admin messages:', error);
    sendResponse(res, 500, false, 'Failed to fetch admin messages.');
  }
});

// ─── POST /api/v1/admin-messages ─────────────────────────────────────────────
// Only admins can send messages to principals.
router.post('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { message, schoolIds, sendToAll } = req.body;

    if (!message || !message.trim()) {
      return sendResponse(res, 400, false, 'message is required.');
    }

    const FCM_TITLE = '📢 Message from Admin';

    if (sendToAll) {
      // ── Broadcast to every principal ──────────────────────────────
      const notice = await prisma.notifications.create({
        data: {
          id: crypto.randomUUID(),
          title: FCM_TITLE,
          message: message.trim(),
          user_email: null,
          channel: 'app',
          status: 'sent',
        },
      });

      // Push to all principals that have an FCM token
      const allPrincipals = await prisma.principals.findMany({
        where: { fcm_token: { not: null }, status: 'active' },
        select: { fcm_token: true },
      });

      await Promise.allSettled(
        allPrincipals.map((p) => sendFcmPush(p.fcm_token, FCM_TITLE, message.trim()))
      );

      return sendResponse(res, 201, true, 'Broadcast admin message sent.', notice);
    }

    if (!schoolIds || !Array.isArray(schoolIds) || schoolIds.length === 0) {
      return sendResponse(res, 400, false, 'No schoolIds provided.');
    }

    // ── Send to specific schools ──────────────────────────────────
    const principals = await prisma.principals.findMany({
      where: { school_id: { in: schoolIds } },
    });

    if (principals.length === 0) {
      return sendResponse(res, 404, false, 'No principals found for the selected schools.');
    }

    // Save a DB notification for each principal
    const creations = principals.map((principal) =>
      prisma.notifications.create({
        data: {
          id: crypto.randomUUID(),
          title: FCM_TITLE,
          message: message.trim(),
          user_email: principal.email ? principal.email.toLowerCase().trim() : null,
          channel: 'app',
          status: 'sent',
        },
      })
    );
    await Promise.all(creations);

    // Fire FCM push to each principal that has a token
    await Promise.allSettled(
      principals
        .filter((p) => p.fcm_token)
        .map((p) => sendFcmPush(p.fcm_token, FCM_TITLE, message.trim()))
    );

    sendResponse(res, 201, true, 'Admin messages sent successfully.');
  } catch (error) {
    console.error('Failed to create admin message:', error);
    sendResponse(res, 500, false, 'Failed to create admin message.');
  }
});

// ─── PUT /api/v1/admin-messages/:id/read ─────────────────────────────────────
// Mark a notification as read on the server (principal only).
router.put('/:id/read', authenticate, authorize('principal', 'admin'), async (req, res) => {
  try {
    const notice = await prisma.notifications.findUnique({ where: { id: req.params.id } });
    if (!notice) return sendResponse(res, 404, false, 'Message not found.');

    await prisma.notifications.update({
      where: { id: req.params.id },
      data: { read_at: new Date(), status: 'read' },
    });

    sendResponse(res, 200, true, 'Message marked as read.');
  } catch (error) {
    console.error('Failed to mark message as read:', error);
    sendResponse(res, 500, false, 'Failed to mark message as read.');
  }
});

// ─── POST /api/v1/admin-messages/reply ───────────────────────────────────────
// Principal sends a reply / message back to the admin.
// Stored as a notification with channel='reply' and user_email = principal's email.
router.post('/reply', authenticate, authorize('principal'), async (req, res) => {
  try {
    const { message } = req.body;

    if (!message || !message.trim()) {
      return sendResponse(res, 400, false, 'message is required.');
    }

    const email = req.user?.email?.toLowerCase().trim();
    if (!email) return sendResponse(res, 401, false, 'Unauthorised.');

    // Look up principal to get school info
    const principal = await prisma.principals.findUnique({ where: { email } });

    const senderLabel = principal
      ? `${principal.principal_name} (${principal.school_name})`
      : email;

    const notice = await prisma.notifications.create({
      data: {
        id: crypto.randomUUID(),
        title: `📩 Reply from ${senderLabel}`,
        message: message.trim(),
        user_email: email,
        channel: 'reply',
        status: 'sent',
      },
    });

    sendResponse(res, 201, true, 'Reply sent to admin.', {
      id: notice.id,
      title: notice.title,
      message: notice.message,
      sentAt: notice.created_at,
    });
  } catch (error) {
    console.error('Failed to send principal reply:', error);
    sendResponse(res, 500, false, 'Failed to send reply.');
  }
});

// ─── GET /api/v1/admin-messages/replies ──────────────────────────────────────
// Admin fetches all replies sent by principals.
router.get('/replies', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { schoolId, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = { channel: 'reply' };

    if (schoolId) {
      // Resolve email(s) of principals belonging to that school
      const principals = await prisma.principals.findMany({
        where: { school_id: schoolId },
        select: { email: true },
      });
      const emails = principals.map((p) => p.email.toLowerCase().trim());
      if (emails.length === 0) {
        return res.json([]);
      }
      where.user_email = { in: emails };
    }

    const [replies, total] = await Promise.all([
      prisma.notifications.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { created_at: 'desc' },
      }),
      prisma.notifications.count({ where }),
    ]);

    const formatted = replies.map((r) => ({
      id: r.id,
      title: r.title,
      message: r.message,
      from_email: r.user_email,
      sentAt: r.created_at,
      status: r.status,
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Failed to fetch replies:', error);
    sendResponse(res, 500, false, 'Failed to fetch replies.');
  }
});

module.exports = router;

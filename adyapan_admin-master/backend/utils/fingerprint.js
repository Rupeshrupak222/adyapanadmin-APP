/**
 * Request Fingerprinting — Identify unique clients without cookies
 * 
 * Creates a hash from: IP + User-Agent + Accept-Language + Accept-Encoding
 * Used to detect:
 *   - Same attacker using multiple accounts
 *   - Credential stuffing (same fingerprint, many emails)
 *   - Session hijacking (fingerprint mismatch)
 */

const crypto = require('crypto');

/**
 * Generate a request fingerprint
 * @param {object} req - Express request object
 * @returns {string} SHA-256 hash (first 16 chars)
 */
function generateFingerprint(req) {
  const components = [
    req.ip || req.connection?.remoteAddress || 'unknown',
    req.get('user-agent') || 'no-ua',
    req.get('accept-language') || 'no-lang',
    req.get('accept-encoding') || 'no-enc',
    req.get('sec-ch-ua-platform') || '',
  ];

  const raw = components.join('|');
  return crypto.createHash('sha256').update(raw).digest('hex').slice(0, 16);
}

/**
 * Track fingerprints for anomaly detection
 * Detects: same fingerprint trying multiple emails (credential stuffing)
 */
const fingerprintTracker = new Map(); // fingerprint → { emails: Set, lastSeen }

const trackerTimer = setInterval(() => {
  const now = Date.now();
  for (const [fp, data] of fingerprintTracker.entries()) {
    if (now - data.lastSeen > 60 * 60 * 1000) { // 1 hour TTL
      fingerprintTracker.delete(fp);
    }
  }
}, 30 * 60 * 1000);
trackerTimer.unref();

/**
 * Track a login attempt by fingerprint
 * @returns {{ suspicious: boolean, uniqueEmails: number }}
 */
function trackAttempt(fingerprint, email) {
  let data = fingerprintTracker.get(fingerprint);
  if (!data) {
    data = { emails: new Set(), lastSeen: Date.now(), attempts: 0 };
    fingerprintTracker.set(fingerprint, data);
  }

  data.emails.add(email.toLowerCase());
  data.lastSeen = Date.now();
  data.attempts += 1;

  // Suspicious: same client trying 5+ different emails in 1 hour
  const suspicious = data.emails.size >= 5;

  return { suspicious, uniqueEmails: data.emails.size, totalAttempts: data.attempts };
}

module.exports = { generateFingerprint, trackAttempt };

/**
 * Security Event Logger — Audit trail for all security-relevant events
 * 
 * Logs to console (structured JSON) + can be extended to file/external service.
 * Events: login_success, login_failed, account_locked, token_revoked, 
 *         password_changed, suspicious_activity, rate_limited
 */

const crypto = require('crypto');

const SEVERITY = {
  INFO: 'info',
  WARN: 'warn',
  CRITICAL: 'critical',
};

/**
 * Log a security event
 */
function logSecurityEvent(event) {
  const entry = {
    timestamp: new Date().toISOString(),
    eventId: crypto.randomUUID(),
    type: event.type,
    severity: event.severity || SEVERITY.INFO,
    email: event.email || null,
    userId: event.userId || null,
    ip: event.ip || null,
    userAgent: event.userAgent ? event.userAgent.slice(0, 200) : null,
    details: event.details || null,
    fingerprint: event.fingerprint || null,
  };

  // Structured log output (parseable by log aggregators)
  if (entry.severity === SEVERITY.CRITICAL) {
    console.error('[SECURITY:CRITICAL]', JSON.stringify(entry));
  } else if (entry.severity === SEVERITY.WARN) {
    console.warn('[SECURITY:WARN]', JSON.stringify(entry));
  } else {
    console.log('[SECURITY:INFO]', JSON.stringify(entry));
  }

  return entry;
}

// Convenience methods
function logLoginSuccess(data) {
  return logSecurityEvent({ type: 'login_success', severity: SEVERITY.INFO, ...data });
}

function logLoginFailed(data) {
  return logSecurityEvent({ type: 'login_failed', severity: SEVERITY.WARN, ...data });
}

function logAccountLocked(data) {
  return logSecurityEvent({ type: 'account_locked', severity: SEVERITY.CRITICAL, ...data });
}

function logTokenRevoked(data) {
  return logSecurityEvent({ type: 'token_revoked', severity: SEVERITY.INFO, ...data });
}

function logPasswordChanged(data) {
  return logSecurityEvent({ type: 'password_changed', severity: SEVERITY.INFO, ...data });
}

function logSuspiciousActivity(data) {
  return logSecurityEvent({ type: 'suspicious_activity', severity: SEVERITY.CRITICAL, ...data });
}

function logRateLimited(data) {
  return logSecurityEvent({ type: 'rate_limited', severity: SEVERITY.WARN, ...data });
}

module.exports = {
  SEVERITY,
  logSecurityEvent,
  logLoginSuccess,
  logLoginFailed,
  logAccountLocked,
  logTokenRevoked,
  logPasswordChanged,
  logSuspiciousActivity,
  logRateLimited,
};

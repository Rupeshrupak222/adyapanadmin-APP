/**
 * Account Lockout — Lock account after 5 consecutive failed attempts
 * 
 * Lockout duration: 15 minutes (escalates with repeated lockouts)
 * Auto-unlock after timer expires.
 * 
 * For multi-instance: replace Map with Redis HASH + TTL.
 */

const accounts = new Map(); // email → { failures, lockedUntil, lockCount }

const LOCKOUT_THRESHOLD = 5;
const BASE_LOCKOUT_MS = 15 * 60 * 1000; // 15 minutes
const MAX_LOCKOUT_MS = 60 * 60 * 1000;  // 1 hour max

// Cleanup every 30 minutes
const timer = setInterval(() => {
  const now = Date.now();
  for (const [email, data] of accounts.entries()) {
    if (data.lockedUntil && now > data.lockedUntil && data.failures === 0) {
      accounts.delete(email);
    }
  }
}, 30 * 60 * 1000);
timer.unref();

/**
 * Check if account is currently locked
 * @returns {{ locked: boolean, remainingMs: number, attempts: number }}
 */
function isLocked(email) {
  const key = email.toLowerCase().trim();
  const data = accounts.get(key);
  if (!data) return { locked: false, remainingMs: 0, attempts: 0 };

  if (data.lockedUntil && Date.now() < data.lockedUntil) {
    return {
      locked: true,
      remainingMs: data.lockedUntil - Date.now(),
      attempts: data.failures,
    };
  }

  // Lock expired — reset if was locked
  if (data.lockedUntil && Date.now() >= data.lockedUntil) {
    data.failures = 0;
    data.lockedUntil = null;
  }

  return { locked: false, remainingMs: 0, attempts: data.failures };
}

/**
 * Record a failed login attempt
 * @returns {{ locked: boolean, attempts: number, lockDurationMs: number }}
 */
function recordFailure(email) {
  const key = email.toLowerCase().trim();
  let data = accounts.get(key);

  if (!data) {
    data = { failures: 0, lockedUntil: null, lockCount: 0 };
    accounts.set(key, data);
  }

  // If lock expired, reset failures
  if (data.lockedUntil && Date.now() >= data.lockedUntil) {
    data.failures = 0;
    data.lockedUntil = null;
  }

  data.failures += 1;

  if (data.failures >= LOCKOUT_THRESHOLD) {
    data.lockCount += 1;
    // Escalating lockout: 15min, 30min, 45min, 60min max
    const lockDuration = Math.min(BASE_LOCKOUT_MS * data.lockCount, MAX_LOCKOUT_MS);
    data.lockedUntil = Date.now() + lockDuration;
    return { locked: true, attempts: data.failures, lockDurationMs: lockDuration };
  }

  return { locked: false, attempts: data.failures, lockDurationMs: 0 };
}

/**
 * Clear failures on successful login
 */
function clearFailures(email) {
  const key = email.toLowerCase().trim();
  const data = accounts.get(key);
  if (data) {
    data.failures = 0;
    data.lockedUntil = null;
    // Keep lockCount for escalation history
  }
}

/**
 * Admin: manually unlock an account
 */
function adminUnlock(email) {
  accounts.delete(email.toLowerCase().trim());
}

module.exports = { isLocked, recordFailure, clearFailures, adminUnlock };

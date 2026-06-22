/**
 * Progressive Delay for failed login attempts
 * 
 * 1st fail: 1 second
 * 2nd fail: 3.5 seconds
 * 3rd fail: 10 seconds
 * 4th+ fail: 15 seconds
 * 
 * Auto-resets after 15 minutes of inactivity.
 * In-memory store — for multi-instance deployments, replace with Redis.
 */

const failedAttempts = new Map();

// Cleanup old entries every 30 minutes — unref() so it doesn't block shutdown
const cleanupTimer = setInterval(() => {
  const now = Date.now();
  for (const [key, data] of failedAttempts.entries()) {
    if (now - data.lastAttempt > 30 * 60 * 1000) {
      failedAttempts.delete(key);
    }
  }
}, 30 * 60 * 1000);
cleanupTimer.unref();

function getDelay(attemptCount) {
  if (attemptCount <= 1) return 1000;
  if (attemptCount === 2) return 3500;
  if (attemptCount === 3) return 10000;
  return 15000;
}

/**
 * Record a failed login attempt and apply progressive delay.
 * The delay happens server-side — attacker must wait regardless.
 */
async function recordFailedAttempt(email) {
  const key = email.toLowerCase().trim();
  const now = Date.now();

  let existing = failedAttempts.get(key);

  if (!existing || (now - existing.lastAttempt > 15 * 60 * 1000)) {
    existing = { count: 0, lastAttempt: now };
  }

  existing.count += 1;
  existing.lastAttempt = now;
  failedAttempts.set(key, existing);

  const delay = getDelay(existing.count);
  await new Promise((resolve) => setTimeout(resolve, delay));

  return { attempts: existing.count, delayMs: delay };
}

/**
 * Clear failed attempts on successful login
 */
function clearFailedAttempts(email) {
  failedAttempts.delete(email.toLowerCase().trim());
}

/**
 * Get current attempt count (for logging/monitoring)
 */
function getAttemptCount(email) {
  const data = failedAttempts.get(email.toLowerCase().trim());
  if (!data) return 0;
  if (Date.now() - data.lastAttempt > 15 * 60 * 1000) {
    failedAttempts.delete(email.toLowerCase().trim());
    return 0;
  }
  return data.count;
}

module.exports = { recordFailedAttempt, clearFailedAttempts, getAttemptCount };

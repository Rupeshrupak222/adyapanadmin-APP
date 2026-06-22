/**
 * Token Blacklist — Immediate token revocation
 * 
 * In-memory store with TTL cleanup.
 * For multi-instance: replace with Redis SET with TTL.
 * 
 * Usage:
 *   blacklistToken(jti, expiresInSeconds)
 *   isBlacklisted(jti) → boolean
 */

const blacklist = new Map(); // jti → expiry timestamp

// Cleanup expired entries every 10 minutes
const cleanupTimer = setInterval(() => {
  const now = Date.now();
  for (const [jti, expiry] of blacklist.entries()) {
    if (now > expiry) blacklist.delete(jti);
  }
}, 10 * 60 * 1000);
cleanupTimer.unref();

/**
 * Add a token to blacklist
 * @param {string} jti - JWT ID (unique token identifier)
 * @param {number} ttlSeconds - Time until token naturally expires
 */
function blacklistToken(jti, ttlSeconds = 28800) {
  if (!jti) return;
  blacklist.set(jti, Date.now() + (ttlSeconds * 1000));
}

/**
 * Check if a token is blacklisted
 * @param {string} jti - JWT ID
 * @returns {boolean}
 */
function isBlacklisted(jti) {
  if (!jti) return false;
  const expiry = blacklist.get(jti);
  if (!expiry) return false;
  if (Date.now() > expiry) {
    blacklist.delete(jti);
    return false;
  }
  return true;
}

/**
 * Blacklist all tokens for a user (logout everywhere)
 * Stores user ID with timestamp — any token issued before this is invalid
 */
const userRevocations = new Map(); // userId → timestamp

function revokeAllUserTokens(userId) {
  userRevocations.set(userId, Date.now());
}

function isUserTokenRevoked(userId, tokenIssuedAt) {
  const revokedAt = userRevocations.get(userId);
  if (!revokedAt) return false;
  // Token issued before revocation = invalid
  return (tokenIssuedAt * 1000) < revokedAt;
}

module.exports = {
  blacklistToken,
  isBlacklisted,
  revokeAllUserTokens,
  isUserTokenRevoked,
};

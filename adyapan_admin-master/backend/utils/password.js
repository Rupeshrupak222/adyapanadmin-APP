const argon2 = require('argon2');
const crypto = require('crypto');

// Argon2id config (OWASP recommended)
const ARGON2_OPTIONS = {
  type: argon2.argon2id,
  memoryCost: 65536,   // 64 MB
  timeCost: 3,         // 3 iterations
  parallelism: 1,      // 1 thread
};

/**
 * Hash password using Argon2id
 */
async function hashPassword(password) {
  return argon2.hash(password, ARGON2_OPTIONS);
}

/**
 * Verify password against stored hash
 * Supports: Argon2id, bcrypt (legacy), SHA-256 (legacy seed)
 * Uses constant-time comparison to prevent timing attacks
 */
async function verifyPassword(password, hash) {
  if (!hash || !password) return false;

  // Argon2 hash
  if (hash.startsWith('$argon2')) {
    let match = await argon2.verify(hash, password).catch(() => false);
    if (match) return true;

    // Also try with SHA-256 pre-hash (some older records were stored this way)
    const sha256 = crypto.createHash('sha256').update(password).digest('hex');
    match = await argon2.verify(hash, sha256).catch(() => false);
    return match;
  }

  // Legacy bcrypt hash
  if (/^\$2[aby]\$/.test(hash)) {
    const bcrypt = require('bcryptjs');
    let match = await bcrypt.compare(password, hash).catch(() => false);
    if (match) return true;

    // Also try with SHA-256 pre-hash
    const sha256 = crypto.createHash('sha256').update(password).digest('hex');
    match = await bcrypt.compare(sha256, hash).catch(() => false);
    return match;
  }

  // SHA-256 hash (64-character hex string)
  if (/^[0-9a-f]{64}$/i.test(hash)) {
    const inputHash = crypto.createHash('sha256').update(password).digest('hex');
    try {
      if (crypto.timingSafeEqual(Buffer.from(inputHash, 'utf8'), Buffer.from(hash, 'utf8'))) {
        return true;
      }
    } catch {}

    // Also allow comparing the raw password if it happens to be a 64-char hex string
    if (password.length === hash.length) {
      try {
        if (crypto.timingSafeEqual(Buffer.from(password, 'utf8'), Buffer.from(hash, 'utf8'))) {
          return true;
        }
      } catch {}
    }
    return false;
  }

  // Plain text (legacy seed data only) — constant-time comparison
  if (password.length !== hash.length) return false;
  const a = Buffer.from(password, 'utf8');
  const b = Buffer.from(hash, 'utf8');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/**
 * Check if hash needs upgrade to Argon2id
 */
function needsRehash(hash) {
  if (!hash) return true;
  return !hash.startsWith('$argon2');
}

/**
 * Generate 256-bit access key (hex)
 */
function generateAccessKey() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Hash access key using SHA-256 (store only this in DB)
 */
function hashAccessKey(accessKey) {
  return crypto.createHash('sha256').update(accessKey).digest('hex');
}

/**
 * Verify access key against stored hash (constant-time)
 */
function verifyAccessKey(accessKey, storedHash) {
  if (!accessKey || !storedHash) return false;
  const hash = hashAccessKey(accessKey);
  try {
    return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(storedHash, 'hex'));
  } catch {
    return false;
  }
}

module.exports = {
  hashPassword,
  verifyPassword,
  needsRehash,
  generateAccessKey,
  hashAccessKey,
  verifyAccessKey,
};

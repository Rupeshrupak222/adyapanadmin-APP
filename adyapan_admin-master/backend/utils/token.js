const jwt = require('jsonwebtoken');
const crypto = require('crypto');

/**
 * Token utility — uses separate secrets for access and refresh tokens
 * to prevent token type confusion attacks.
 */

function getSecrets() {
  const base = process.env.JWT_SECRET;
  if (!base) throw new Error('JWT_SECRET not configured');

  return {
    access: base,
    // Derive refresh secret from base to avoid needing 2 env vars
    // but ensure they're cryptographically different
    refresh: crypto.createHmac('sha256', base).update('refresh-token-salt').digest('hex'),
  };
}

function generateAccessToken(user) {
  const secrets = getSecrets();
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      type: 'access',
      jti: crypto.randomUUID(), // Unique token ID for blacklisting
    },
    secrets.access,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      issuer: 'adyapan-backend',
      audience: 'adyapan-app',
    }
  );
}

function generateRefreshToken(user) {
  const secrets = getSecrets();
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      type: 'refresh',
      // Add jti (JWT ID) for future revocation support
      jti: crypto.randomUUID(),
    },
    secrets.refresh,
    {
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
      issuer: 'adyapan-backend',
      audience: 'adyapan-app',
    }
  );
}

function verifyAccessToken(token) {
  const secrets = getSecrets();
  const decoded = jwt.verify(token, secrets.access, {
    issuer: 'adyapan-backend',
    audience: 'adyapan-app',
  });

  // Reject if someone tries to use a refresh token as access token
  if (decoded.type !== 'access') {
    throw new jwt.JsonWebTokenError('Invalid token type');
  }

  return decoded;
}

function verifyRefreshToken(token) {
  const secrets = getSecrets();
  const decoded = jwt.verify(token, secrets.refresh, {
    issuer: 'adyapan-backend',
    audience: 'adyapan-app',
  });

  if (decoded.type !== 'refresh') {
    throw new jwt.JsonWebTokenError('Invalid token type');
  }

  return decoded;
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};

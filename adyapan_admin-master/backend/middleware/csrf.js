/**
 * CSRF Protection — Double-Submit Cookie Pattern
 * 
 * How it works:
 * 1. Server sets a random CSRF token in a non-httpOnly cookie (readable by JS)
 * 2. Client reads cookie and sends token in X-CSRF-Token header
 * 3. Server verifies header matches cookie
 * 
 * This works because:
 * - Attacker can't read cookies from another origin (SameSite + CORS)
 * - Attacker can't set custom headers in cross-origin requests
 * 
 * Exempt: GET, HEAD, OPTIONS (safe methods) + API routes with Bearer token
 */

const crypto = require('crypto');
const { sendResponse } = require('../utils/response');

const CSRF_COOKIE = 'adyapan_csrf';
const CSRF_HEADER = 'x-csrf-token';
const TOKEN_LENGTH = 32;

/**
 * Generate CSRF token
 */
function generateCsrfToken() {
  return crypto.randomBytes(TOKEN_LENGTH).toString('hex');
}

/**
 * CSRF middleware — sets cookie on GET, validates on mutations
 */
function csrfProtection(req, res, next) {
  // Exempt: requests from Dart/Flutter mobile apps (bypasses CSRF for API clients)
  const userAgent = req.headers['user-agent'] || '';
  if (userAgent.includes('Dart/Flutter')) {
    return next();
  }

  // Safe methods don't need CSRF check
  const safeMethods = ['GET', 'HEAD', 'OPTIONS'];
  if (safeMethods.includes(req.method)) {
    // Set/refresh CSRF cookie on safe requests
    if (!req.cookies?.[CSRF_COOKIE]) {
      const token = generateCsrfToken();
      res.cookie(CSRF_COOKIE, token, {
        httpOnly: false, // Must be readable by JavaScript
        sameSite: 'strict',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        maxAge: 60 * 60 * 8 * 1000, // 8 hours
      });
    }
    return next();
  }

  // Mutation requests (POST, PUT, DELETE, PATCH)

  // Exempt: login and registration routes
  const exemptPaths = ['/api/v1/auth/login', '/api/v1/auth/register'];
  if (exemptPaths.includes(req.path) || req.path.startsWith('/api/v1/auth/login')) {
    return next();
  }

  // Exempt: requests with Bearer token (API clients, mobile apps)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return next();
  }

  // Validate CSRF token
  const cookieToken = req.cookies?.[CSRF_COOKIE];
  const headerToken = req.headers[CSRF_HEADER];

  if (!cookieToken || !headerToken) {
    return sendResponse(res, 403, false, 'CSRF token missing. Please refresh the page.');
  }

  // Constant-time comparison
  if (cookieToken.length !== headerToken.length) {
    return sendResponse(res, 403, false, 'CSRF token invalid.');
  }

  const valid = crypto.timingSafeEqual(
    Buffer.from(cookieToken, 'utf8'),
    Buffer.from(headerToken, 'utf8')
  );

  if (!valid) {
    return sendResponse(res, 403, false, 'CSRF token mismatch.');
  }

  next();
}

module.exports = { csrfProtection, generateCsrfToken, CSRF_COOKIE };

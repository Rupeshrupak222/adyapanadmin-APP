const { verifyAccessToken } = require('../utils/token');
const { sendResponse } = require('../utils/response');
const { isBlacklisted, isUserTokenRevoked } = require('../utils/token-blacklist');

/**
 * Authenticate JWT access token from Authorization header.
 * Checks:
 *   1. Token exists and is valid
 *   2. Token type is 'access' (not refresh)
 *   3. Token is not blacklisted (logout)
 *   4. User hasn't revoked all tokens (logout-all / password change)
 */
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendResponse(res, 401, false, 'Access denied. No token provided.');
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyAccessToken(token);

    // Check if this specific token is blacklisted
    if (decoded.jti && isBlacklisted(decoded.jti)) {
      return sendResponse(res, 401, false, 'Token has been revoked. Please login again.');
    }

    // Check if all user tokens were revoked (password change / logout-all)
    if (decoded.iat && isUserTokenRevoked(decoded.id, decoded.iat)) {
      return sendResponse(res, 401, false, 'Session expired. Please login again.');
    }

    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return sendResponse(res, 401, false, 'Token expired. Please login again.');
    }
    return sendResponse(res, 401, false, 'Invalid token.');
  }
}

/**
 * Role-based authorization middleware.
 */
function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return sendResponse(res, 401, false, 'Authentication required.');
    }
    if (!allowedRoles.includes(req.user.role)) {
      return sendResponse(
        res, 403, false,
        `Access denied. Required: ${allowedRoles.join(' or ')}. Your role: ${req.user.role}`
      );
    }
    next();
  };
}

module.exports = { authenticate, authorize };

const { sendResponse } = require('../utils/response');

/**
 * Validate required fields in request body
 */
function validateBody(...requiredFields) {
  return (req, res, next) => {
    const missing = requiredFields.filter(
      (field) => req.body[field] === undefined || req.body[field] === null || req.body[field] === ''
    );
    if (missing.length > 0) {
      return sendResponse(res, 400, false, `Missing required fields: ${missing.join(', ')}`);
    }
    next();
  };
}

/**
 * Strict email validation
 * - Only alphanumerics, dots, underscores, hyphens allowed in local part
 * - Exactly one @ character
 * - Domain must be alphanumeric with dots
 * - No special characters like !, #, $, %, etc.
 */
function validateEmail(req, res, next) {
  const { email } = req.body;
  if (!email) return next();

  const trimmed = email.trim().toLowerCase();

  // Only allow: alphanumerics, dots, underscores, hyphens + exactly one @
  // Local part: [a-z0-9._-]+
  // Domain: [a-z0-9.-]+\.[a-z]{2,}
  const strictEmailRegex = /^[a-z0-9][a-z0-9._-]*@[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/;

  if (!strictEmailRegex.test(trimmed)) {
    return sendResponse(res, 400, false, 'Invalid email. Only alphanumerics, dots, hyphens, underscores and one @ allowed.');
  }

  // Check no consecutive dots
  if (/\.\./.test(trimmed)) {
    return sendResponse(res, 400, false, 'Invalid email. Consecutive dots not allowed.');
  }

  // Check only one @
  if ((trimmed.match(/@/g) || []).length !== 1) {
    return sendResponse(res, 400, false, 'Invalid email. Exactly one @ required.');
  }

  req.body.email = trimmed;
  next();
}

/**
 * Validate password strength
 * - Minimum 6 characters
 */
function validatePassword(req, res, next) {
  const { password } = req.body;
  if (password && password.length < 6) {
    return sendResponse(res, 400, false, 'Password must be at least 6 characters.');
  }
  next();
}

module.exports = { validateBody, validateEmail, validatePassword };

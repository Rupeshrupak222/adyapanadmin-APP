/**
 * Input Sanitization — XSS Prevention
 * 
 * Strips dangerous HTML/script content from all string inputs.
 * Applied to req.body, req.query, req.params.
 * 
 * Does NOT modify:
 * - Non-string values (numbers, booleans, arrays)
 * - Password fields (they get hashed anyway)
 * - Fields explicitly whitelisted
 */

const SKIP_FIELDS = ['password', 'currentPassword', 'newPassword', 'refreshToken', 'token', 'accessKey', 'staffKey', 'schoolKey'];

/**
 * Remove dangerous characters/patterns from a string
 */
function sanitizeString(str) {
  if (typeof str !== 'string') return str;

  return str
    // Remove script tags and content
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    // Remove event handlers
    .replace(/on\w+\s*=\s*["'][^"']*["']/gi, '')
    // Remove javascript: protocol
    .replace(/javascript\s*:/gi, '')
    // Remove data: protocol (can execute JS)
    .replace(/data\s*:\s*text\/html/gi, '')
    // Remove HTML tags (keep content)
    .replace(/<[^>]*>/g, '')
    // Remove null bytes
    .replace(/\0/g, '')
    // Trim excessive whitespace
    .trim();
}

/**
 * Recursively sanitize an object
 */
function sanitizeObject(obj, depth = 0) {
  if (depth > 10) return obj; // Prevent infinite recursion
  if (obj === null || obj === undefined) return obj;
  if (typeof obj === 'string') return sanitizeString(obj);
  if (typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map((item) => sanitizeObject(item, depth + 1));

  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    // Skip password/token fields
    if (SKIP_FIELDS.includes(key)) {
      sanitized[key] = value;
    } else {
      sanitized[key] = sanitizeObject(value, depth + 1);
    }
  }
  return sanitized;
}

/**
 * Express middleware — sanitize req.body, req.query, req.params
 */
function inputSanitizer(req, res, next) {
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObject(req.query);
  }
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeObject(req.params);
  }
  next();
}

module.exports = { inputSanitizer, sanitizeString, sanitizeObject };

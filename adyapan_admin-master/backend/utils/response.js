/**
 * Standardized API Response Format
 */

function sendResponse(res, statusCode, success, message, data = null, meta = null) {
  const response = { success, message, statusCode };
  if (data !== null) response.data = data;
  if (meta !== null) response.meta = meta;
  return res.status(statusCode).json(response);
}

function sendPaginatedResponse(res, data, total, page, limit) {
  return sendResponse(res, 200, true, 'Data fetched successfully', data, {
    total,
    page: parseInt(page),
    limit: parseInt(limit),
    totalPages: Math.ceil(total / limit),
  });
}

module.exports = { sendResponse, sendPaginatedResponse };

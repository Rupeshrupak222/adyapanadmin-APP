require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });

// ─── Validate required env vars ─────────────────────────────────────
const REQUIRED_ENV = ['DATABASE_URL', 'JWT_SECRET'];
const missing = REQUIRED_ENV.filter((key) => !process.env[key]);
if (missing.length > 0) {
  console.error(`❌ Missing required env vars: ${missing.join(', ')}`);
  console.error('   Check your .env file or Render environment settings.');
  process.exit(1);
}

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const hpp = require('hpp');
const cookieParser = require('cookie-parser');
const prisma = require('./lib/prisma');
const { inputSanitizer } = require('./middleware/sanitize');
const { csrfProtection } = require('./middleware/csrf');

// Route imports
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const studentRoutes = require('./routes/students');
const teacherRoutes = require('./routes/teachers');
const schoolRoutes = require('./routes/schools');
const liveClassRoutes = require('./routes/liveClasses');
const eventRoutes = require('./routes/events');
const leaveRoutes = require('./routes/leaves');
const meetingRoutes = require('./routes/meetings');
const leadRoutes = require('./routes/leads');
const attendanceRoutes = require('./routes/attendance');
const classRoutes = require('./routes/classes');
const paymentRoutes = require('./routes/payments');
const noticeRoutes = require('./routes/notices');
const dashboardRoutes = require('./routes/dashboard');
const bulkImportRoutes = require('./routes/bulk-import');
const adminMessageRoutes = require('./routes/admin-messages');

const app = express();
const PORT = process.env.PORT || 4000;
const isProduction = process.env.NODE_ENV === 'production';

// ─── Security Middleware ─────────────────────────────────────────────
app.use(helmet());

// ─── CORS Configuration ─────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin) return callback(null, true);
      // In dev, allow all; in production, check whitelist
      if (!isProduction || allowedOrigins.length === 0) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// ─── Rate Limiting ──────────────────────────────────────────────────
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // 200 requests per window
  message: { success: false, message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // Stricter for auth routes (prevent brute force)
  message: { success: false, message: 'Too many login attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', generalLimiter);
app.use('/api/v1/auth/', authLimiter);

// ─── Compression ────────────────────────────────────────────────────
app.use(compression());

// ─── Body Parsing ───────────────────────────────────────────────────
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
app.use(cookieParser());

// ─── HTTP Parameter Pollution Protection ────────────────────────────
app.use(hpp());

// ─── Input Sanitization (XSS Prevention) ────────────────────────────
app.use(inputSanitizer);

// ─── CSRF Protection (Double-Submit Cookie) ─────────────────────────
app.use(csrfProtection);

// ─── Logging ────────────────────────────────────────────────────────
if (isProduction) {
  app.use(morgan('combined'));
} else {
  app.use(morgan('dev'));
}

// ─── Health Check (with DB ping) ────────────────────────────────────
app.get('/', async (req, res) => {
  let dbStatus = 'unknown';
  try {
    await prisma.$queryRaw`SELECT 1`;
    dbStatus = 'connected';
  } catch {
    dbStatus = 'disconnected';
  }

  const response = {
    status: dbStatus === 'connected' ? 'ok' : 'degraded',
    message: 'Adyapan Unified Backend',
    version: '3.0.0',
    database: dbStatus,
    uptime: Math.floor(process.uptime()) + 's',
  };

  // Only expose details in development
  if (!isProduction) {
    response.environment = 'development';
    response.endpoints = [
      '/api/v1/auth', '/api/v1/profile', '/api/v1/students',
      '/api/v1/teachers', '/api/v1/schools', '/api/v1/live-classes',
      '/api/v1/events', '/api/v1/leaves', '/api/v1/meetings',
      '/api/v1/leads', '/api/v1/attendance', '/api/v1/classes',
      '/api/v1/payments', '/api/v1/notices', '/api/v1/dashboard',
    ];
  }

  res.json(response);
});

// ─── API Routes ─────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/students', studentRoutes);
app.use('/api/v1/teachers', teacherRoutes);
app.use('/api/v1/schools', schoolRoutes);
app.use('/api/v1/live-classes', liveClassRoutes);
app.use('/api/v1/events', eventRoutes);
app.use('/api/v1/leaves', leaveRoutes);
app.use('/api/v1/meetings', meetingRoutes);
app.use('/api/v1/leads', leadRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/classes', classRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/notices', noticeRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/bulk-import', bulkImportRoutes);
app.use('/api/v1/admin-messages', adminMessageRoutes);
app.use('/api/v1/messages', adminMessageRoutes);

// ─── 404 Handler ────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
});

// ─── Global Error Handler ───────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Server Error:', err.stack || err.message);
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: isProduction ? 'Internal server error' : err.message,
  });
});

// ─── Graceful Shutdown ──────────────────────────────────────────────
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Adyapan Unified Backend running on http://0.0.0.0:${PORT}`);
  console.log(`📦 Database: TiDB Cloud via Prisma`);
  console.log(`🔐 Security: Helmet + Rate Limit + CORS`);
  console.log(`🌐 Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}`);
});

async function gracefulShutdown(signal) {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    await prisma.$disconnect();
    console.log('✅ Database disconnected. Server closed.');
    process.exit(0);
  });

  // Force shutdown after 10s
  setTimeout(() => {
    console.error('⚠️ Forced shutdown after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// ─── Unhandled Errors (prevent silent crashes) ──────────────────────
process.on('unhandledRejection', (reason, promise) => {
  console.error('⚠️ Unhandled Rejection:', reason);
  // Don't exit — log and continue
});

process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  // Exit on uncaught — state may be corrupted
  gracefulShutdown('uncaughtException');
});

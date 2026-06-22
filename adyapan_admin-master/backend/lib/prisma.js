const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

// Verify DB connection on startup (non-blocking)
prisma.$connect()
  .then(() => console.log('✅ Prisma connected to database'))
  .catch((err) => {
    console.error('❌ Prisma DB connection failed:', err.message);
    console.error('   Check DATABASE_URL in your .env file.');
    // Don't exit — let health check report degraded status
  });

module.exports = prisma;

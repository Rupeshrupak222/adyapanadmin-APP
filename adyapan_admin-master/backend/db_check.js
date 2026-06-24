const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const messages = await prisma.$queryRawUnsafe('SELECT * FROM admin_messages ORDER BY created_at DESC LIMIT 5');
    console.log('Latest 5 messages in DB:');
    console.log(JSON.stringify(messages, null, 2));
  } catch (err) {
    console.error('Error querying DB:', err.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();

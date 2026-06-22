const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.users.findMany();
  console.log('--- USERS LIST ---');
  for (const u of users) {
    console.log(`ID: ${u.id} | Email: ${u.email} | Name: ${u.name} | Role: ${u.role} | Password (plain/hash): ${u.password} | PasswordHash: ${u.password_hash}`);
  }
  console.log('------------------');
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());

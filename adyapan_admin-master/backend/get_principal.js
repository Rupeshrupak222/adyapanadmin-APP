const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const newUser = await prisma.users.create({
    data: {
      id: 'principal_sharda_001',
      email: 'principal@shardamandir.com',
      name: 'Dr. Sunita Patil',
      role: 'principal',
      password: 'f6acf258da641d77f7b2cc3a306a425932d739586e5e2bf91577bf84a8b0debb',
      password_hash: 'f6acf258da641d77f7b2cc3a306a425932d739586e5e2bf91577bf84a8b0debb',
      school_name: 'Sharda Mandir High School',
      school_id: 'cmq53oxrj0004tkkok4klr2f2'
    }
  });
  console.log('Created user:', newUser);
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());

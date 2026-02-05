import { PrismaClient } from '@prisma/client';
import * as jose from 'jose';
import { config } from 'dotenv';

config();

const prisma = new PrismaClient();

async function main() {
  // Create test user
  const user = await prisma.user.upsert({
    where: { email: 'test@verbio.app' },
    update: {},
    create: {
      appleUserId: 'test-apple-user-id',
      email: 'test@verbio.app',
      firstName: 'Test',
      lastName: 'User',
      subscriptionTier: 'FREE',
    },
  });
  
  console.log('Test user ID:', user.id);
  
  // Generate JWT token
  const privateKeyPem = process.env.JWT_PRIVATE_KEY;
  if (!privateKeyPem) {
    console.error('JWT_PRIVATE_KEY not set in .env');
    process.exit(1);
  }
  
  const privateKey = await jose.importPKCS8(privateKeyPem, 'ES256');
  
  const token = await new jose.SignJWT({
    sub: user.id,
    email: user.email,
    tier: user.subscriptionTier,
  })
    .setProtectedHeader({ alg: 'ES256', typ: 'JWT' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .setIssuer('verbio-api')
    .setAudience('verbio-ios')
    .sign(privateKey);
  
  console.log('');
  console.log('ACCESS_TOKEN=' + token);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

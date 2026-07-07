import dotenv from 'dotenv';
dotenv.config();

const jwtSecret = process.env.JWT_SECRET ?? 'konekta-dev-secret-change-me';

// Warn if using the default secret in production
if (process.env.NODE_ENV === 'production' && jwtSecret === 'konekta-dev-secret-change-me') {
  console.error('[FATAL] JWT_SECRET must be set to a secure random value in production!');
  process.exit(1);
}

export const env = {
  port: Number(process.env.PORT ?? 4000),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  db: {
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD ?? '',
    database: process.env.DB_NAME ?? 'konekta',
  },
  jwtSecret,
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET ?? '',
  googleRedirectUri: process.env.GOOGLE_REDIRECT_URI ?? 'http://localhost:4000/auth/google/callback',
  allowedOrigins: process.env.ALLOWED_ORIGINS ?? '',
};

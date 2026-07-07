import { OAuth2Client } from 'google-auth-library';
import { env } from './env';

export const clientId = env.googleClientId || process.env.GOOGLE_CLIENT_ID;
export const clientSecret = env.googleClientSecret || process.env.GOOGLE_CLIENT_SECRET;
export const redirectUri = env.googleRedirectUri;

export const client = new OAuth2Client(clientId, clientSecret, redirectUri);

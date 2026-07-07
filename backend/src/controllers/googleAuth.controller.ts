import { Request, Response } from 'express';
import { OAuth2Client, LoginTicket } from 'google-auth-library';
import bcrypt from 'bcryptjs';
import { pool, DbRow, DbResult } from '../config/db';
import { signToken, AuthPayload } from '../middlewares/auth';
import { client, clientId } from '../config/googleOAuth';

function googleAuthUrl() {
  return client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: ['email', 'profile'],
  });
}

/** Find or create user from Google payload, return JWT. */
async function resolveGoogleUser(
  email: string,
  name: string,
): Promise<{ token: string; user: AuthPayload }> {
  // Check if user exists
  const [existing] = await pool.query<DbRow[]>(
    'SELECT id, name, email, role FROM users WHERE email = ? LIMIT 1',
    [email]
  );

  let userId: number;
  let role: 'influencer' | 'brand';

  if (existing.length) {
    const u = existing[0] as { id: number; name: string; email: string; role: 'influencer' | 'brand' };
    userId = u.id;
    role = u.role;
  } else {
    // Create new user — default role influencer, they can change in onboarding
    const hash = await bcrypt.hash(Math.random().toString(36), 10); // random hash, no password login
    const [ins] = await pool.query<DbResult>(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name || email.split('@')[0], email, hash, 'influencer']
    );
    userId = ins.insertId;
    role = 'influencer';
    // Create influencer profile stub
    const username = email.split('@')[0].replace(/[^a-z0-9_]/gi, '').slice(0, 80) || `user${userId}`;
    await pool.query(
      `INSERT IGNORE INTO influencer_profiles (user_id, username) VALUES (?, ?)`,
      [userId, username]
    );
  }

  const [userRows] = await pool.query<DbRow[]>(
    'SELECT id, name, email, role FROM users WHERE id = ? LIMIT 1',
    [userId]
  );
  const u = userRows[0] as { id: number; name: string; email: string; role: 'influencer' | 'brand' };
  const payload: AuthPayload = { id: u.id, role: u.role, email: u.email, name: u.name };
  const token = signToken(payload);
  return { token, user: payload };
}

export async function googleAuth(_req: Request, res: Response) {
  res.redirect(googleAuthUrl());
}

export async function googleAuthMobile(_req: Request, res: Response) {
  res.json({ auth_url: googleAuthUrl() });
}

export async function googleCallback(req: Request, res: Response) {
  try {
    const { code } = req.query;
    if (!code) return res.status(400).json({ success: false, message: 'Authorization code required' });

    const { tokens } = await client.getToken(code as string);
    client.setCredentials(tokens);

    const ticket: LoginTicket = await client.verifyIdToken({
      idToken: tokens.id_token ?? '',
      audience: clientId ?? '',
    });

    const p = ticket.getPayload();
    if (!p) throw new Error('No payload');

    const result = await resolveGoogleUser(p.email ?? '', p.name ?? '');
    return res.json({ success: true, message: 'Google OAuth login successful', data: result });
  } catch (err) {
    console.error('[google callback]', err);
    return res.status(401).json({ success: false, message: 'Google authentication failed' });
  }
}

export async function googleExchange(req: Request, res: Response) {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ success: false, message: 'Authorization code is required' });

    const { tokens } = await client.getToken(code);
    client.setCredentials(tokens);

    const ticket: LoginTicket = await client.verifyIdToken({
      idToken: tokens.id_token ?? '',
      audience: clientId ?? '',
    });

    const p = ticket.getPayload();
    if (!p) throw new Error('No payload');

    const result = await resolveGoogleUser(p.email ?? '', p.name ?? '');
    return res.json({ success: true, message: 'Google OAuth login successful', data: result });
  } catch (err) {
    console.error('[google exchange]', err);
    return res.status(401).json({ success: false, message: 'Google authentication failed' });
  }
}

export async function googleIdToken(req: Request, res: Response) {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ success: false, message: 'idToken is required' });

    const verifier = new OAuth2Client(clientId);
    const ticket: LoginTicket = await verifier.verifyIdToken({
      idToken,
      audience: clientId ?? '',
    });

    const p = ticket.getPayload();
    if (!p) throw new Error('No payload');

    const result = await resolveGoogleUser(p.email ?? '', p.name ?? '');
    return res.json({ success: true, message: 'Google Sign-In successful', data: result });
  } catch (err) {
    console.error('[google idtoken]', err);
    return res.status(401).json({ success: false, message: 'Google authentication failed' });
  }
}

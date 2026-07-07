import { Request, Response } from 'express';
import { LoginTicket } from 'google-auth-library';
import { client } from './googleOAuth.config';
import User from './models/User';
import BearerToken from './models/BearerToken';

function googleAuthUrl() {
  return client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: ['email', 'profile'],
  });
}

export async function googleAuth(_req: Request, res: Response) {
  const url = googleAuthUrl();
  res.redirect(url);
}

export async function googleAuthMobile(req: Request, res: Response) {
  const url = googleAuthUrl();
  res.json({ auth_url: url });
}

export async function googleCallback(req: Request, res: Response) {
  try {
    const { code } = req.query;
    if (!code) return res.status(400).json({ error: 'Authorization code required' });

    const { tokens } = await client.getToken(code as string);
    client.setCredentials(tokens);

    const ticket: LoginTicket = await client.verifyIdToken({
      idToken: tokens.id_token ?? '',
      audience: process.env.GOOGLE_CLIENT_ID ?? '',
    });

    const payload = ticket.getPayload();
    if (!payload) throw new Error('No payload');

    const { email, name, sub: googleId } = payload;

    const user = await User.findOrCreateOAuth({
      email: email ?? '', name: name ?? '', provider: 'google', providerId: googleId ?? '',
    });

    const tokenData = await BearerToken.create(user.id);

    res.json({
      message: 'Google OAuth login successful',
      user: { id: user.id, email: user.email, name: user.name ?? '' },
      token: tokenData.token,
      expires_at: tokenData.expiresAt,
    });
  } catch (err) {
    console.error('Google callback error:', err);
    res.status(401).json({ error: 'Google authentication failed' });
  }
}

export async function googleExchange(req: Request, res: Response) {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ error: 'Authorization code is required' });

    const { tokens } = await client.getToken(code);
    client.setCredentials(tokens);

    const ticket: LoginTicket = await client.verifyIdToken({
      idToken: tokens.id_token ?? '',
      audience: process.env.GOOGLE_CLIENT_ID ?? '',
    });

    const payload = ticket.getPayload();
    if (!payload) throw new Error('No payload');

    const { email, name, sub: googleId } = payload;

    const user = await User.findOrCreateOAuth({
      email: email ?? '', name: name ?? '', provider: 'google', providerId: googleId ?? '',
    });

    const tokenData = await BearerToken.create(user.id);

    res.json({
      message: 'Google OAuth login successful',
      user: { id: user.id, email: user.email, name: user.name ?? '' },
      token: tokenData.token,
      expires_at: tokenData.expiresAt,
    });
  } catch (err) {
    console.error('Google exchange error:', err);
    res.status(401).json({ error: 'Google authentication failed' });
  }
}

import bcrypt from 'bcryptjs';
import { pool, DbRow, DbResult } from '../../config/db';
import { signToken, AuthPayload } from '../../core/middlewares/auth';
import { ApiError } from '../../core/utils/apiError';

export interface RegisterInput {
  name: string;
  email: string;
  password: string;
  role: 'influencer' | 'brand';
  username?: string;
  brand_name?: string;
}

export const authService = {
  async register(input: RegisterInput) {
    const { name, email, password, role, username, brand_name } = input;

    const [existing] = await pool.query<DbRow[]>(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email]
    );
    if (existing.length) throw new ApiError(409, 'Email already registered');

    const hash = await bcrypt.hash(password, 10);
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const [ins] = await conn.query<DbResult>(
        'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
        [name, email, hash, role]
      );
      const userId = ins.insertId;

      if (role === 'influencer') {
        const u = username ?? email.split('@')[0];
        await conn.query(
          `INSERT INTO influencer_profiles (user_id, username) VALUES (?, ?)`,
          [userId, u]
        );
      } else {
        const b = brand_name ?? `${name}'s Brand`;
        await conn.query(
          `INSERT INTO brand_profiles (user_id, brand_name) VALUES (?, ?)`,
          [userId, b]
        );
      }

      await conn.commit();

      const payload: AuthPayload = { id: userId, role, email, name };
      const token = signToken(payload);
      return { token, user: payload };
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  },

  async login(email: string, password: string) {
    const [rows] = await pool.query<DbRow[]>(
      'SELECT id, name, email, password_hash, role FROM users WHERE email = ? LIMIT 1',
      [email]
    );
    if (!rows.length) throw new ApiError(401, 'Invalid email or password');
    const user = rows[0] as { id: number; name: string; email: string; password_hash: string; role: 'influencer'|'brand' };
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) throw new ApiError(401, 'Invalid email or password');
    const payload: AuthPayload = { id: user.id, role: user.role, email: user.email, name: user.name };
    const token = signToken(payload);
    return { token, user: payload };
  },

  async forgotPassword(email: string) {
    const [rows] = await pool.query<DbRow[]>(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email]
    );
    // Always succeed to avoid leaking which emails are registered
    return { delivered: rows.length > 0 };
  },
};

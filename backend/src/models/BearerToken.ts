import crypto from 'crypto';
import { pool, DbRow, DbResult } from '../config/db';

const TOKEN_LENGTH = 20;
const TOKEN_EXPIRY_HOURS = parseInt(process.env.TOKEN_EXPIRY_HOURS ?? '') || 24;

class BearerToken {
  static generateToken() {
    return crypto.randomBytes(TOKEN_LENGTH).toString('hex');
  }

  static async create(userId: number) {
    const token = this.generateToken();
    const expiresAt = new Date(Date.now() + TOKEN_EXPIRY_HOURS * 60 * 60 * 1000);
    const [result] = await pool.query<DbResult>(
      'INSERT INTO bearer_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
      [userId, token, expiresAt]
    );
    return { token, expiresAt, id: result.insertId };
  }

  static async verify(token: string) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT bt.*, u.email, u.name, u.provider
       FROM bearer_tokens bt
       JOIN users u ON bt.user_id = u.id
       WHERE bt.token = ? AND bt.expires_at > NOW()`,
      [token]
    );
    return (rows[0] as DbRow & { user_id: number }) || null;
  }

  static async revoke(token: string) {
    const [result] = await pool.query<DbResult>('DELETE FROM bearer_tokens WHERE token = ?', [token]);
    return result.affectedRows > 0;
  }

  static async revokeAllForUser(userId: number) {
    await pool.query('DELETE FROM bearer_tokens WHERE user_id = ?', [userId]);
  }
}

export default BearerToken;

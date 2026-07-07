import { pool, DbRow, DbResult } from '../config/db';

export interface UserRecord {
  id: number;
  email: string;
  name: string;
  role: 'influencer' | 'brand';
  provider?: string;
  provider_id?: string;
}

class User {
  static async findByEmail(email: string) {
    const [rows] = await pool.query<DbRow[]>('SELECT * FROM users WHERE email = ?', [email]);
    return (rows[0] as UserRecord) || null;
  }

  static async findById(id: number) {
    const [rows] = await pool.query<DbRow[]>('SELECT * FROM users WHERE id = ?', [id]);
    return (rows[0] as UserRecord) || null;
  }

  static async findByProvider(provider: string, providerId: string) {
    const [rows] = await pool.query<DbRow[]>(
      'SELECT * FROM users WHERE provider = ? AND provider_id = ?',
      [provider, providerId]
    );
    return (rows[0] as UserRecord) || null;
  }

  static async create({
    email, password, name, role = 'influencer',
    provider = 'local', providerId = null,
  }: {
    email: string;
    password: string;
    name: string;
    role?: 'influencer' | 'brand';
    provider?: string;
    providerId?: string | null;
  }) {
    const [result] = await pool.query<DbResult>(
      'INSERT INTO users (email, password, name, role, provider, provider_id) VALUES (?, ?, ?, ?, ?, ?)',
      [email, password, name, role, provider, providerId]
    );
    return result.insertId;
  }

  static async findOrCreateOAuth({
    email, name, provider, providerId,
  }: {
    email: string;
    name: string;
    provider: string;
    providerId: string;
  }) {
    const existing = await this.findByProvider(provider, providerId);
    if (existing) return existing;

    const id = await this.create({
      email, password: '', name,
      role: 'influencer', provider, providerId,
    });
    return this.findById(id);
  }
}

export default User;

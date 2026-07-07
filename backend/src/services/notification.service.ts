import { pool, DbRow } from '../config/db';

export const notificationService = {
  async list(userId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, type, title, body, data, is_read, read_status, created_at
         FROM notifications
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 200`,
      [userId]
    );
    return rows;
  },

  async unreadCount(userId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT COUNT(*) AS n FROM notifications WHERE user_id = ? AND is_read = 0`,
      [userId]
    );
    return Number((rows[0] as { n: number }).n) || 0;
  },

  async markRead(userId: number, ids: number[]) {
    if (!ids.length) return { updated: 0 };
    const placeholders = ids.map(() => '?').join(',');
    const [r] = await pool.query(
      `UPDATE notifications SET is_read = 1, read_status = 1
        WHERE user_id = ? AND id IN (${placeholders})`,
      [userId, ...ids]
    );
    return { updated: (r as { affectedRows: number }).affectedRows };
  },

  async markOneRead(userId: number, id: number) {
    const [r] = await pool.query(
      `UPDATE notifications SET is_read = 1, read_status = 1
        WHERE user_id = ? AND id = ?`,
      [userId, id]
    );
    return { updated: (r as { affectedRows: number }).affectedRows };
  },

  async markAllRead(userId: number) {
    const [r] = await pool.query(
      `UPDATE notifications SET is_read = 1, read_status = 1 WHERE user_id = ? AND is_read = 0`,
      [userId]
    );
    return { updated: (r as { affectedRows: number }).affectedRows };
  },

  async push(
    userId: number,
    payload: { type: string; title: string; body: string; data?: unknown }
  ) {
    const [r] = await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, payload.type, payload.title, payload.body, JSON.stringify(payload.data ?? {})]
    );
    return { id: (r as { insertId: number }).insertId };
  },
};

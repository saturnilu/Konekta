import { pool, DbRow, DbResult } from '../config/db';
import { ApiError } from '../utils/apiError';

export const chatService = {
  async listConversations(userId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT c.id, c.user_a_id, c.user_b_id, c.offer_id,
              c.last_message, c.last_message_at, c.created_at,
              ua.name AS user_a_name, ua.avatar_url AS user_a_avatar,
              ub.name AS user_b_name, ub.avatar_url AS user_b_avatar,
              bp.brand_name, bp.logo_url AS brand_logo,
              ip.username AS influencer_username
         FROM conversations c
         JOIN users ua ON ua.id = c.user_a_id
         JOIN users ub ON ub.id = c.user_b_id
    LEFT JOIN brand_profiles bp ON (bp.user_id = c.user_a_id OR bp.user_id = c.user_b_id)
    LEFT JOIN influencer_profiles ip ON (ip.user_id = c.user_a_id OR ip.user_id = c.user_b_id)
        WHERE c.user_a_id = ? OR c.user_b_id = ?
        ORDER BY c.last_message_at DESC`,
      [userId, userId]
    );
    return rows;
  },

  async ensureConversation(userAId: number, userBId: number) {
    // Normalize order so (a,b) and (b,a) resolve to same conversation
    const [lo, hi] = userAId < userBId ? [userAId, userBId] : [userBId, userAId];
    const [exists] = await pool.query<DbRow[]>(
      `SELECT id FROM conversations
        WHERE user_a_id = ? AND user_b_id = ? LIMIT 1`,
      [lo, hi]
    );
    if (exists.length) return exists[0] as { id: number };
    const [r] = await pool.query<DbResult>(
      `INSERT INTO conversations (user_a_id, user_b_id) VALUES (?, ?)`,
      [lo, hi]
    );
    return { id: r.insertId };
  },

  async ensureConversationByOtherUser(currentUserId: number, otherUserId: number) {
    return this.ensureConversation(currentUserId, otherUserId);
  },

  async listMessages(conversationId: number, userId: number) {
    await this.assertMember(conversationId, userId);
    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, conversation_id, sender_user_id,
              message_text AS body, attachment_url, created_at,
              (sender_user_id = ?) AS is_mine
         FROM messages
        WHERE conversation_id = ?
        ORDER BY created_at ASC`,
      [userId, conversationId]
    );
    return rows;
  },

  async sendMessage(conversationId: number, senderId: number, body: string) {
    await this.assertMember(conversationId, senderId);
    const [r] = await pool.query<DbResult>(
      `INSERT INTO messages (conversation_id, sender_user_id, message_text) VALUES (?, ?, ?)`,
      [conversationId, senderId, body]
    );
    await pool.query(
      `UPDATE conversations SET last_message = ?, last_message_at = NOW() WHERE id = ?`,
      [body, conversationId]
    );
    return { id: r.insertId, conversation_id: conversationId, sender_user_id: senderId, body };
  },

  async assertMember(conversationId: number, userId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT user_a_id, user_b_id FROM conversations WHERE id = ?`,
      [conversationId]
    );
    if (!rows.length) throw new ApiError(404, 'Conversation not found');
    const c = rows[0] as { user_a_id: number; user_b_id: number };
    if (c.user_a_id !== userId && c.user_b_id !== userId) {
      throw new ApiError(403, 'Not a member of this conversation');
    }
  },
};

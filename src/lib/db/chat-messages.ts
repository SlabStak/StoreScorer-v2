import 'server-only';

import { callFunction, DbResult } from '../db';
import { ChatMessage, ChatMessageCreateInput } from '@/types/db';

function mapMessage(row: Record<string, unknown>): ChatMessage {
  return {
    id: row.id as string,
    auditId: row.audit_id as string,
    userId: row.user_id as string,
    role: row.role as ChatMessage['role'],
    content: row.content as string,
    createdAt: new Date(row.created_at as string),
  };
}

export async function createChatMessage(
  userId: string,
  input: ChatMessageCreateInput
): Promise<DbResult<ChatMessage>> {
  const result = await callFunction<Record<string, unknown>>(
    'create_chat_message',
    [userId, input.auditId, input.role, input.content]
  );

  if (result.success && result.data) {
    return { success: true, data: mapMessage(result.data) };
  }

  return result as DbResult<ChatMessage>;
}

export async function listChatMessages(
  userId: string,
  auditId: string,
  limit = 100
): Promise<DbResult<{ items: ChatMessage[]; total: number }>> {
  const result = await callFunction<{
    items: Record<string, unknown>[];
    total: number;
  }>('list_chat_messages', [userId, auditId, limit]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        items: result.data.items.map(mapMessage),
        total: result.data.total,
      },
    };
  }

  return result as DbResult<{ items: ChatMessage[]; total: number }>;
}

export async function countUserChatMessages(
  userId: string,
  since?: Date
): Promise<DbResult<{ count: number; since: Date }>> {
  const result = await callFunction<{
    count: number;
    since: string;
  }>('count_user_chat_messages', [userId, since?.toISOString()]);

  if (result.success && result.data) {
    return {
      success: true,
      data: {
        count: result.data.count,
        since: new Date(result.data.since),
      },
    };
  }

  return result as DbResult<{ count: number; since: Date }>;
}

export async function deleteChatMessagesForAudit(
  userId: string,
  auditId: string
): Promise<DbResult<{ deletedCount: number }>> {
  const result = await callFunction<{ deleted_count: number }>(
    'delete_chat_messages_for_audit',
    [userId, auditId]
  );

  if (result.success && result.data) {
    return {
      success: true,
      data: { deletedCount: result.data.deleted_count },
    };
  }

  return result as DbResult<{ deletedCount: number }>;
}

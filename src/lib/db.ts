import { Pool, PoolClient, QueryResult } from 'pg';

// Singleton pool with globalThis caching for development hot-reload
const globalForPg = globalThis as unknown as { pgPool: Pool | undefined };

const pool = globalForPg.pgPool ?? new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,                    // Maximum connections in pool
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 10000, // Fail if can't connect in 10s
});

if (process.env.NODE_ENV !== 'production') {
  globalForPg.pgPool = pool;
}

/**
 * Result wrapper type for all database operations
 */
export interface DbResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * Call a PostgreSQL function and return typed result
 * This is the PRIMARY way to interact with the database
 */
export async function callFunction<T>(
  functionName: string,
  args: unknown[] = []
): Promise<DbResult<T>> {
  const client = await pool.connect();

  try {
    // Build parameterized query: SELECT function_name($1, $2, ...) as result
    const placeholders = args.map((_, i) => `$${i + 1}`).join(', ');
    const sql = `SELECT ${functionName}(${placeholders}) as result`;

    const result = await client.query(sql, args);

    // Parse JSONB result from PostgreSQL function
    const jsonResult = result.rows[0]?.result;

    if (!jsonResult) {
      return { success: false, error: 'No result from function' };
    }

    return jsonResult as DbResult<T>;
  } catch (error) {
    console.error(`Database function ${functionName} failed:`, error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown database error',
    };
  } finally {
    client.release();
  }
}

/**
 * Execute raw SQL query (use sparingly - prefer callFunction)
 */
export async function query<T>(
  sql: string,
  params: unknown[] = []
): Promise<QueryResult<T>> {
  const client = await pool.connect();
  try {
    return await client.query<T>(sql, params);
  } finally {
    client.release();
  }
}

/**
 * Get a client for transaction support
 */
export async function getClient(): Promise<PoolClient> {
  return pool.connect();
}

/**
 * Execute multiple operations in a transaction
 */
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Graceful shutdown
 */
export async function closePool(): Promise<void> {
  await pool.end();
}

export { pool };

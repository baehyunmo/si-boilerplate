/**
 * Database connection and ORM configuration.
 *
 * This module provides a database connection manager that can be configured
 * via environment variables. Plug in your ORM of choice (Prisma, TypeORM,
 * Drizzle, Knex, etc.) here.
 */

export interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  username: string;
  password: string;
  ssl: boolean;
  poolMin: number;
  poolMax: number;
}

/** Read database config from environment variables with sensible defaults. */
export function loadDatabaseConfig(env: Record<string, string | undefined> = process.env): DatabaseConfig {
  return {
    host: env['DB_HOST'] ?? 'localhost',
    port: parseInt(env['DB_PORT'] ?? '5432', 10),
    database: env['DB_NAME'] ?? 'app',
    username: env['DB_USER'] ?? 'app',
    password: env['DB_PASSWORD'] ?? '',
    ssl: env['DB_SSL'] === 'true',
    poolMin: parseInt(env['DB_POOL_MIN'] ?? '2', 10),
    poolMax: parseInt(env['DB_POOL_MAX'] ?? '10', 10),
  };
}

/**
 * Abstract connection manager. Implement connect/disconnect for your ORM.
 */
export abstract class DatabaseConnection {
  protected config: DatabaseConfig;

  constructor(config: DatabaseConfig) {
    this.config = config;
  }

  abstract connect(): Promise<void>;
  abstract disconnect(): Promise<void>;
  abstract isConnected(): boolean;
}

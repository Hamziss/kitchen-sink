/**
 * Type-safe environment configuration index
 *
 * This file serves as the central export point for environment variables.
 * Import from here throughout your application to ensure type safety.
 *
 * @example
 * ```typescript
 * import { env } from '@/config';
 *
 * const port = env.PORT;
 * const dbUrl = env.DATABASE_URL;
 * ```
 */

import { env } from "./env-validation";

/**
 * Helper to check if we're in development mode
 */
export const isDev = process.env.NODE_ENV === "development";

/**
 * Helper to check if we're in production mode
 */
export const isProd = process.env.NODE_ENV === "production";

/**
 * Helper to check if we're in test mode
 */
export const isTest = process.env.NODE_ENV === "test";

/**
 * Helper to get logs root directory
 */
export const LogsRoot = env.LOGS_ROOT;

export { type Env, env } from "./env-validation";

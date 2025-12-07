import { bool, cleanEnv, num, port, str, url } from "envalid";

/**
 * Environment variable validation schema using envalid
 *
 * This configuration provides type-safe environment variables with runtime validation.
 * All variables are server-side only (envalid is designed for Node.js backends).
 */
export const env = cleanEnv(process.env, {
	// Project configuration
	PROJECT_NAME: str({ default: "Viva" }),
	ENABLE_SWAGGER: bool({ default: true }),
	BACK_URL: str({ default: "http://localhost:5000" }),

	// Node environment
	NODE_ENV: str({
		choices: ["development", "production", "test"],
		default: "development",
	}),

	// Server configuration
	PORT: port({ default: 5000 }),
	HOST: str({ default: "localhost" }),

	// Database configuration
	DATABASE_URL: str(),

	// CORS configuration
	CORS_ORIGIN: str({ default: "http://localhost:5173" }),

	// Rate limiting
	RATE_LIMIT_WINDOW_MS: num({ default: 900000 }), // 15 minutes
	RATE_LIMIT_MAX_REQUESTS: num({ default: 100 }),

	// External services (optional)
	REDIS_URL: url({ default: undefined }),

	// File upload configuration
	MAX_FILE_SIZE: num({ default: 10485760 }), // 10MB
	UPLOAD_DIR: str({ default: "./uploads" }),

	// Logging
	LOG_LEVEL: str({
		choices: ["error", "warn", "info", "debug"],
		default: "info",
	}),
	LOGS_ROOT: str({ default: "./logs" }),
});

/**
 * Export the type of the validated environment for use in other files
 */
export type Env = typeof env;

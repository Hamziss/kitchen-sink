/**
 * Server initialization and lifecycle management
 *
 * This module handles:
 * - Server startup and initialization
 * - Graceful shutdown on termination signals
 * - Error handling for uncaught exceptions and unhandled rejections
 * - Database connection management
 */

import type { Server } from "node:http";
import { app } from "./app";
import { env, isDev } from "./config/env";
import { globalLogger } from "./lib/Logger";

const PORT = env.PORT;

let server: Server | null = null;

/**
 * System class for managing application lifecycle
 */
class System {
	/**
	 * Initialize application dependencies and connections
	 */
	static async Start(): Promise<void> {
		try {
			// Initialize database connections here
			// Example: await prisma.$connect();

			globalLogger.info("✅ All systems initialized successfully");
		} catch (error) {
			globalLogger.error("Failed to initialize system:", error);
			throw error;
		}
	}

	/**
	 * Cleanup and close all connections
	 */
	static async Stop(): Promise<void> {
		try {
			// Close database connections here
			// Example: await prisma.$disconnect();

			globalLogger.info("🛑 All connections closed successfully");
		} catch (error) {
			globalLogger.error("Error during system shutdown:", error);
			throw error;
		}
	}

	/**
	 * Force process termination after timeout
	 * @param seconds - Timeout in seconds before force exit
	 */
	static async ProcessError(seconds: number): Promise<void> {
		setTimeout(() => {
			globalLogger.error("Force terminating process after timeout");
			process.exit(1);
		}, seconds * 1000);
	}
}

/**
 * Graceful shutdown handler
 * Ensures clean closure of all connections and resources
 */
async function gracefulShutdown(signal: string): Promise<void> {
	globalLogger.info(`\n${signal} received. Starting graceful shutdown...`);

	// Stop accepting new connections
	if (server) {
		server.close(() => {
			globalLogger.info("HTTP server closed");
		});
	}

	try {
		await System.Stop();
		globalLogger.info("Graceful shutdown completed");
		process.exit(0);
	} catch (error) {
		globalLogger.error("Error during graceful shutdown:", error);
		process.exit(1);
	}
}

/**
 * Start the server (skip in test environment)
 */
if (process.env.NODE_ENV !== "test") {
	System.Start()
		.then(() => {
			server = app.listen(PORT, () => {
				// Display server information upon successful start
				const portMsg = `Server running on port: ${PORT}`;
				const urlMsg = `Backend is available at: http://localhost:${PORT}`;
				const envMsg = `Environment: ${env.NODE_ENV}`;
				const docsMsg = `API documentation available at: http://localhost:${PORT}/api-docs`;

				const maxLength = Math.max(portMsg.length, urlMsg.length, envMsg.length, docsMsg.length) + 4;

				const createCenteredLine = (text: string) => {
					const padding = Math.floor((maxLength - text.length) / 2);
					const extraSpace = (maxLength - text.length) % 2;
					return `|${" ".repeat(padding)}${text}${" ".repeat(padding + extraSpace)}|`;
				};

				globalLogger.info(` ${"─".repeat(maxLength)}`);
				globalLogger.info(createCenteredLine(portMsg));
				globalLogger.info(createCenteredLine(urlMsg));
				if (env.ENABLE_SWAGGER) {
					globalLogger.info(createCenteredLine(docsMsg));
				}
				globalLogger.info(createCenteredLine(envMsg));
				globalLogger.info(` ${"─".repeat(maxLength)}`);
			});
		})
		.catch((error) => {
			globalLogger.error("Failed to start server:", error);
			process.exit(1);
		});
}

/**
 * Handle termination signals for graceful shutdown
 */
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

/**
 * Handle uncaught exceptions
 */
process.on("uncaughtException", (error: Error) => {
	globalLogger.error("Uncaught Exception:", error);
	gracefulShutdown("uncaughtException");
});

/**
 * Handle unhandled promise rejections
 */
process.on("unhandledRejection", (reason: unknown, promise: Promise<unknown>) => {
	globalLogger.error(`Unhandled Rejection at: ${promise}, reason: ${reason}`);
	gracefulShutdown("unhandledRejection");
});

/**
 * Export server stop function for testing purposes
 */
export async function StopServer(): Promise<void> {
	await System.Stop();
	if (server) {
		server.close();
	}
}

export default System;

import { PrismaPg } from "@prisma/adapter-pg";
import { env } from "@/config/env";
import { PrismaClient } from "@/generated/prisma/client";

const connectionString = env.DATABASE_URL;

/**
 * Prisma PostgreSQL adapter
 * Prisma v7 uses driver adapters for database connections
 */
const adapter = new PrismaPg({
	connectionString,
});

/**
 * Global Prisma Client instance
 * Uses singleton pattern to prevent multiple instances in development (hot reload)
 */
const globalForPrisma = globalThis as unknown as {
	prisma: PrismaClient | undefined;
};

export const db =
	globalForPrisma.prisma ??
	new PrismaClient({
		adapter,
		log: env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
	});

if (env.NODE_ENV !== "production") {
	globalForPrisma.prisma = db;
}

/**
 * Graceful shutdown handler
 * Disconnects Prisma and closes the connection pool
 */
export async function disconnectDb(): Promise<void> {
	await db.$disconnect();
}

export default db;

import { type Request, type Response, Router } from "express";
import db from "@/lib/db";

// import { prisma } from "@/lib/prisma";

const healthRouter = Router();

healthRouter.get("/", async (_req: Request, res: Response) => {
	// #swagger.tags = ['Health']
	// #swagger.summary = 'Overall health check'
	// #swagger.description = 'Check the health status of the application and Prisma (database).'
	const health = {
		ping: "pong",
		uptime: process.uptime(),
		timestamp: Date.now(),
		status: "OK",
		checks: {
			database: "DOWN",
		},
	};

	try {
		// Check Prisma database connection
		await db.$queryRaw`SELECT 1`;
		health.checks.database = "UP";

		// If any service is down, return 503
		if (health.checks.database !== "UP") {
			health.status = "DEGRADED";
			return res.status(503).json(health);
		}

		return res.status(200).json(health);
	} catch {
		health.status = "ERROR";
		return res.status(503).json(health);
	}
});

healthRouter.get("/ready", async (_req: Request, res: Response) => {
	// #swagger.tags = ['Health']
	// #swagger.summary = 'Readiness probe'
	// #swagger.description = 'Check if the application is ready to serve traffic (Kubernetes-ready).'
	try {
		// Check if Prisma database is ready
		await db.$queryRaw`SELECT 1`;
		return res.status(200).json({ status: "ready" });
	} catch {
		return res.status(503).json({ status: "not ready" });
	}
});

healthRouter.get("/live", (_req: Request, res: Response) => {
	// #swagger.tags = ['Health']
	// #swagger.summary = 'Liveness probe'
	// #swagger.description = 'Check if the application is alive (Kubernetes-ready).'
	res.status(200).json({ status: "alive" });
});

export default healthRouter;

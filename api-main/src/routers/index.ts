import type { Application } from "express";
import healthRouter from "./health.router";

export default function SetRouters(app: Application) {
	app.use("/health", healthRouter);
	// ...
}

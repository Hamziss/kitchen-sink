import { Request, Response } from "express";
import { isDev } from "@/config/env";
import { HttpCodes } from "@/config/errors";
import { globalLogger } from "@/lib/Logger";

export class AppError extends Error {
	constructor(
		public message: string,
		public statusCode: number,
	) {
		super(message);
		this.statusCode = statusCode;
		this.name = this.constructor.name;
		Error.captureStackTrace(this, this.constructor);
	}
}

export function errorMiddleware(error: AppError, _req: Request, res: Response, _next: Function) {
	const status = error.statusCode || HttpCodes.InternalServerError.code;
	const message = error.message || HttpCodes.InternalServerError.message;
	const errorDetails = isDev ? error : undefined;

	// Log error for monitoring
	globalLogger.error(`[Error] ${status} - ${message}`, isDev ? error.stack : "");

	return res.status(status).json({
		status: "error",
		message,
		code: status,
		...(errorDetails && { error: errorDetails }),
	});
}

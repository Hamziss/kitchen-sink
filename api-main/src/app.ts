import "./config/env-validation";

import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import { DevCors, ProductionCors } from "./config/cors";
import { isDev } from "./config/env";
import { HttpCodes } from "./config/errors";
import { correlationIdMiddleware } from "./middlewares/correlation-id";
import { errorMiddleware } from "./middlewares/Errors";
import { apiLimiter } from "./middlewares/rate-limitter";
import { requestLoggerMiddleware } from "./middlewares/request-logger";
import SetRouters from "./routers";
import swaggerRouter from "./routers/swagger.router";
import { ErrorResponse } from "./utils/Response";

export const app = express();

/**
 * Security middleware - Helmet for security headers
 */
app.use(helmet());

/**
 * Enable the Express application to trust the first proxy.
 * IMPORTANT: Must be set BEFORE rate limiters to get correct client IPs
 */
app.set("trust proxy", 1);

/**
 * Enable CORS middleware based on the environment.
 */
app.use(isDev ? cors(DevCors) : cors(ProductionCors));

/**
 * Parse cookies in the Express application.
 */
app.use(cookieParser());

/**
 * Correlation ID middleware for request tracking
 * Generates unique ID for each request for debugging and monitoring
 */
app.use(correlationIdMiddleware);

/**
 * HTTP Request logging with correlation ID
 */
app.use(requestLoggerMiddleware);

/**
 * Parse incoming request bodies as URL-encoded data with size limit.
 */
app.use(express.urlencoded({ extended: false, limit: "10mb" }));

/**
 * Parse incoming request bodies as JSON with size limit.
 */
app.use(express.json({ limit: "20mb" }));

/**
 * Apply general API rate limiting
 */
app.use(apiLimiter);

/**
 * Set up docs routes with swaggerRouter
 */
app.use("/api-docs", swaggerRouter);

/**
 * Set up general routes using the `SetRouters` function.
 */
SetRouters(app);

/**
 * Route to handle requests that do not match any defined routes, returning a 404 response.
 */
app.use("/*splat", (_req, res) => ErrorResponse(res, HttpCodes.NotImplemented.code, HttpCodes.NotImplemented.message));

/**
 * Middleware for handling errors throughout the application.
 */
app.use(errorMiddleware);

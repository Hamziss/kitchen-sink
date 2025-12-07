import rateLimit from "express-rate-limit";
import { env } from "../config/env-validation";

export const apiLimiter = rateLimit({
	windowMs: env.RATE_LIMIT_WINDOW_MS,
	limit: env.RATE_LIMIT_MAX_REQUESTS,
	standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
	legacyHeaders: false, // Disable the `X-RateLimit-*` headers
	ipv6Subnet: 56, // Set to 60 or 64 to be less aggressive, or 52 or 48 to be more aggressive
	message: {
		message: "Too many requests from this IP, please try again later.",
	},
	skip: (req) => {
		return req.path === "/health";
	},
});

import assert from "node:assert";
// import { Prisma } from "@prisma/client";
import type { Response as ExpressResponse } from "express";
import { HttpCodes } from "@/config/errors";

export function ErrorResponse(res: ExpressResponse, code: number, errorMessage: string, error?: any) {
	assert(code >= 300, "Error code must be greater than 300");
	let response: ErrorResponse =
		// error instanceof Prisma.PrismaClientValidationError
		// 	? {
		// 			status: "error",
		// 			message: error.message,
		// 			code: HttpCodes.BadRequest.code,
		// 			error,
		// 		}
		// 	: error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002"
		// 		? {
		// 				status: "error",
		// 				message: `Unique constraint failed on the fields: ${(error.meta?.target as string[])?.join(", ")}`,
		// 				code: HttpCodes.BadRequest.code,
		// 				error,
		// 			}
		// 		:
		{
			status: "error",
			message: errorMessage,
			code: code,
			error,
		};

	if (code === HttpCodes.NotFound.code) {
		response = {
			status: "error",
			message: `${errorMessage}`,
			code: HttpCodes.NotFound.code,
			error,
		};
	}
	res.status(response.code).send(response);
}

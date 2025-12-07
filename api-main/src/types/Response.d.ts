interface ErrorResponse {
	status: string;
	message: string;
	code: number;
	error: unknown;
}

interface SuccessResponse {
	status: string;
	data: unknown;
	message: string;
}

export function log(message: string, ...optionalParams: any[]) {
	if (process.env.NODE_ENV !== "test") {
		console.log(message, ...optionalParams);
	}
}

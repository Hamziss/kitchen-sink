import { defineConfig } from "tsup";

export default defineConfig({
	entry: ["src/index.ts"],
	outDir: "dist",
	format: ["esm"],
	target: "node22",
	platform: "node",
	splitting: false,
	sourcemap: true,
	clean: true,
	dts: false,
	minify: true,
	bundle: true,
	skipNodeModulesBundle: true, // Don't bundle node_modules
	esbuildOptions(options) {
		options.alias = {
			"@": "./src",
		};
	},
});

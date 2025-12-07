// import "dotenv/config";
import path from "node:path";
import dotenv from "dotenv";

var envFile = path.resolve(process.cwd(), ".env.dev");
console.log("Using env file:", envFile);
dotenv.config({ path: envFile });

import { db, disconnectDb } from "../src/lib/db";

async function main() {
	console.log("🌱 Seeding database...");

	// Clear existing data (optional - comment out if you want to keep existing data)
	// await db.forums.deleteMany();

	// Seed Forums
	const forums = await db.forums.createMany({
		data: [
			{ title: "General Discussion" },
			{ title: "Announcements" },
			{ title: "Help & Support" },
			{ title: "Feature Requests" },
			{ title: "Off-Topic" },
		],
	});

	console.log(`✅ Created ${forums.count} forums`);

	// Log seeded data
	const allForums = await db.forums.findMany();
	console.log("📋 Seeded forums:", allForums);

	console.log("🌱 Seeding complete!");
}

main()
	.catch((e) => {
		console.error("❌ Seeding failed:", e);
		process.exit(1);
	})
	.finally(async () => {
		await disconnectDb();
	});

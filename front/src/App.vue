<script setup>
import { ref, onMounted } from "vue"
import HelloWorld from "./components/HelloWorld.vue"
import TheWelcome from "./components/TheWelcome.vue"

const items = ref([])

// Fetch items when component loads
onMounted(async () => {
	try {
		const res = await fetch("https://api2.hamziss.com/api/items")
		items.value = await res.json()
	} catch (err) {
		console.error("Failed to load items:", err)
	}
})
</script>

<template>
	<header>
		<img
			alt="Vue logo"
			class="logo"
			src="./assets/logo.svg"
			width="125"
			height="125"
		/>

		<div class="wrapper">
			<HelloWorld msg="You did it!" />
		</div>
	</header>

	<main>
		<!-- Existing component -->
		<TheWelcome />

		<!-- Display items -->
		<div v-if="items.length" class="items">
			<h2>Items</h2>
			<ul>
				<li v-for="item in items" :key="item.id">
					{{ item.name }}
				</li>
			</ul>
		</div>

		<div v-else>
			<p>No items found.</p>
		</div>
	</main>
</template>

<style scoped>
header {
	line-height: 1.5;
}

.logo {
	display: block;
	margin: 0 auto 2rem;
}

@media (min-width: 1024px) {
	header {
		display: flex;
		place-items: center;
		padding-right: calc(var(--section-gap) / 2);
	}

	.logo {
		margin: 0 2rem 0 0;
	}

	header .wrapper {
		display: flex;
		place-items: flex-start;
		flex-wrap: wrap;
	}
}

.items {
	margin-top: 2rem;
}
</style>

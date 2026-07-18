extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"bath",
		"Draw the perfect bath",
		"BATHROOM",
		"20:00",
		1200,
		[
			TaskDefinition.create_step(
				"bath_temperature", "Balance hot and cold water at 38°C", "Brass mixer wheels",
				"Water stabilized at the perfect 38°C.", "Temperature locked. Recovery conditions are ideal.", "temperature"
			),
			TaskDefinition.create_step(
				"bath_fill", "Turn on the faucet", "Faucet lever",
				"The faucet is running. Watch the gold water-level marker."
			),
			TaskDefinition.create_step(
				"bath_stop", "Stop the water inside the gold level band", "Faucet stop lever",
				"Faucet stopped at the perfect level."
			),
			TaskDefinition.create_step(
				"bath_products", "Add soothing bath salts", "Wooden salt bucket",
				"Recovery salts added for aching muscles and battle-weary skin."
			),
			TaskDefinition.create_step(
				"bath_towel_take", "Take a clean towel from the wall closet", "Towel closet",
				"A clean towel has been selected."
			),
			TaskDefinition.create_step(
				"bath_towel_warm", "Place the towel on the warmer", "Towel warmer",
				"Towel warming started. It will be ready in 25 seconds."
			),
			TaskDefinition.create_step(
				"bath_towel_ready", "Collect the warmed towel", "Warmer ready light",
				"The towel is warm and waiting for the master."
			),
			TaskDefinition.create_step(
				"bath_soap_take", "Take a soap cube from the shower cabinet", "Soap cabinet",
				"One fresh soap cube selected."
			),
			TaskDefinition.create_step(
				"bath_soap_refill", "Refill the shower soap holder", "Shower soap holder",
				"The shower has been restocked.",
				"Bath, towel and shower are prepared. Raccoon Man can recover before patrol."
			),
		]
	)

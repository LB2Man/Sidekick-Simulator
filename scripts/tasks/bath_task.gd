extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"bath",
		"Draw the perfect bath",
		"BATHROOM",
		"09:45",
		585,
		24,
		7,
		[
			TaskDefinition.create_step(
				"bath_temperature", "Set water to 39°C", "Warm brass mixer",
				"Water stabilized at a dignified 39°C."
			),
			TaskDefinition.create_step(
				"bath_products", "Add cedar bath salts", "Bath salts",
				"Cedar salts added. Subtle, heroic, pine-adjacent."
			),
			TaskDefinition.create_step(
				"bath_fill", "Fill the tub to the gold line", "Faucet lever",
				"Water has reached the gold line. Do not dawdle."
			),
			TaskDefinition.create_step(
				"bath_stop", "Stop the water before overflow", "Stop valve",
				"Faucet stopped with three centimeters to spare.",
				"Bath telemetry stable. Towels pre-warmed. Rubber duck classified."
			),
		]
	)

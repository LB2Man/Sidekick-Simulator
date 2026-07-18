extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"breakfast",
		"Make the hero's breakfast",
		"KITCHEN",
		"09:00",
		540,
		32,
		9,
		[
			TaskDefinition.create_step(
				"breakfast_eggs", "Collect two moon-hen eggs", "Egg basket",
				"Two moon-hen eggs selected. Neither protested."
			),
			TaskDefinition.create_step(
				"breakfast_coffee", "Brew the extra-dark coffee", "Coffee machine",
				"Coffee brewed: dark enough to conceal an identity."
			),
			TaskDefinition.create_step(
				"breakfast_cook", "Cook eggs to a heroic wobble", "Range",
				"Eggs achieved peak heroic wobble.", "", "timing"
			),
			TaskDefinition.create_step(
				"breakfast_plate", "Plate and ring the service bell", "Serving pass",
				"Breakfast is plated and the silver bell has spoken.",
				"Service bell detected. Raccoon Man's coffee-to-crime ratio is restored."
			),
		]
	)

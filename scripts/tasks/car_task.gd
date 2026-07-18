extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"car",
		"Ready the Raccoon Roadster",
		"GARAGE",
		"11:30",
		690,
		40,
		10,
		[
			TaskDefinition.create_step(
				"car_refuel", "Refill the stealth-fuel tank", "Fuel pump",
				"Stealth-fuel topped up. Smells faintly of almonds."
			),
			TaskDefinition.create_step(
				"car_tires", "Set all tires to 34 PSI", "Tire console",
				"Tires balanced at 34 PSI."
			),
			TaskDefinition.create_step(
				"car_clean", "Remove last night's alley mud", "Wash controls",
				"Alley mud removed. Two parking tickets recovered."
			),
			TaskDefinition.create_step(
				"car_load", "Load spare smoke acorns", "Gadget trunk",
				"Smoke acorns loaded and counted twice.",
				"Roadster checklist complete. Smoke acorns are not snacks, despite the label."
			),
		]
	)

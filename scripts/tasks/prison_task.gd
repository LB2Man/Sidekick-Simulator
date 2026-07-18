extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"prison",
		"Cell service: Doctor Dreadful",
		"PRISON WING",
		"ALL DAY",
		0,
		[
			TaskDefinition.create_step(
				"cell_unlock", "Open the secure service hatch", "Hatch lock",
				"Service hatch open. Main containment remains secure."
			),
			TaskDefinition.create_step(
				"cell_food", "Deliver the approved villain lunch", "Meal cart",
				"Villain lunch delivered: soup, bread, tiny spoon."
			),
			TaskDefinition.create_step(
				"cell_clean", "Sanitize the cell floor", "Cleaning station",
				"Cell floor sanitized under hostile literary criticism."
			),
			TaskDefinition.create_step(
				"cell_lock", "Lock and verify the service hatch", "Security panel",
				"Hatch locked. Doctor Dreadful rates service four stars.",
				"Containment verified. Doctor Dreadful has requested a less cheerful mop."
			),
		]
	)

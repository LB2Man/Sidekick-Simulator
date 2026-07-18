extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"suit",
		"Restore Raccoon Man's suit",
		"WORKSHOP",
		"ALL DAY",
		0,
		[
			TaskDefinition.create_step(
				"suit_inspect", "Scan mud, burns and one dramatic tear", "Inspection scanner",
				"Scan logged: mud, two burns, one suspicious claw mark."
			),
			TaskDefinition.create_step(
				"suit_wash", "Wash on armored-delicates", "Suit washer",
				"Armored-delicates cycle complete."
			),
			TaskDefinition.create_step(
				"suit_dry", "Dry with cool ion air", "Drying chamber",
				"Ion drying complete. Cape static: acceptable."
			),
			TaskDefinition.create_step(
				"suit_repair", "Patch the shoulder tear", "Repair bench",
				"Shoulder tear patched with ballistic thread."
			),
			TaskDefinition.create_step(
				"suit_polish", "Polish the chest emblem", "Polishing wheel",
				"Chest emblem polished to a legally heroic shine."
			),
			TaskDefinition.create_step(
				"suit_display", "Return the suit to its display", "Suit display",
				"Suit restored to the display cradle.",
				"Suit integrity at ninety-nine percent. Cape drama at one hundred and twelve."
			),
		]
	)

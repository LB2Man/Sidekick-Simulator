extends RefCounted

const TaskDefinition = preload("res://scripts/tasks/task_definition.gd")


static func create() -> Dictionary:
	return TaskDefinition.create_task(
		"gadget",
		"Repair the Grapnel-9000",
		"WORKSHOP",
		"—",
		-1,
		45,
		12,
		[
			TaskDefinition.create_step(
				"gadget_open", "Open the scorched casing", "Grapnel casing",
				"Casing open. The scorch mark appears mostly theatrical."
			),
			TaskDefinition.create_step(
				"gadget_wires", "Reconnect the signal wires", "Wire matrix",
				"Signal wires reconnected in the correct dramatic order.",
				"Continuity green. No eyebrows were lost. An above-average repair.", "wires"
			),
			TaskDefinition.create_step(
				"gadget_battery", "Install a charged power cell", "Power cell",
				"Fresh power cell installed at 100% charge."
			),
			TaskDefinition.create_step(
				"gadget_calibrate", "Calibrate launch pressure", "Calibration dial",
				"Launch pressure calibrated. Probably roof-safe.",
				"Pressure curve locked. Please discourage indoor grapnel testing.", "timing"
			),
			TaskDefinition.create_step(
				"gadget_close", "Seal and return the gadget", "Return cradle",
				"Grapnel-9000 sealed and mission-ready.",
				"Grapnel-9000 is back in circulation. The gargoyles have been warned."
			),
		]
	)

extends RefCounted


static func create_task(
	id: String,
	title: String,
	room: String,
	availability_label: String,
	available_from: int,
	steps: Array[Dictionary]
) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"room": room,
		"availability_label": availability_label,
		"available_from": available_from,
		"steps": steps,
		"step_index": 0,
		"status": "active",
	}


static func create_step(
	action: String,
	label: String,
	object_name: String,
	completion_message: String,
	ai_confirmation: String = "",
	minigame: String = ""
) -> Dictionary:
	return {
		"action": action,
		"label": label,
		"object": object_name,
		"completion_message": completion_message,
		"ai_confirmation": ai_confirmation,
		"minigame": minigame,
	}

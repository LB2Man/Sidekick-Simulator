extends RefCounted


static func create_task(
	id: String,
	title: String,
	room: String,
	deadline_label: String,
	deadline: int,
	reward_money: int,
	reward_rep: int,
	steps: Array[Dictionary]
) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"room": room,
		"deadline_label": deadline_label,
		"deadline": deadline,
		"reward_money": reward_money,
		"reward_rep": reward_rep,
		"steps": steps,
		"step_index": 0,
		"status": "active",
		"late": false,
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

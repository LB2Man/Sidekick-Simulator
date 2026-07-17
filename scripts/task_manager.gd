extends Node

signal tasks_changed
signal task_completed(task: Dictionary)
signal deadline_missed(task: Dictionary)
signal rewards_changed(reputation: int, money: int)

const MINIGAME_ACTIONS := {
	"breakfast_cook": "timing",
	"gadget_wires": "wires",
	"gadget_calibrate": "timing",
}

var reputation := 12
var money := 80
var tasks: Array[Dictionary] = []


func _ready() -> void:
	reset_day()


func reset_day() -> void:
	tasks = [
		_task(
			"bath", "Draw the perfect bath", "BATHROOM", "09:45", 585, 24, 7,
			[
				_step("bath_temperature", "Set water to 39°C", "Warm brass mixer"),
				_step("bath_products", "Add cedar bath salts", "Bath salts"),
				_step("bath_fill", "Fill the tub to the gold line", "Faucet lever"),
				_step("bath_stop", "Stop the water before overflow", "Stop valve"),
			]
		),
		_task(
			"breakfast", "Make the hero's breakfast", "KITCHEN", "09:00", 540, 32, 9,
			[
				_step("breakfast_eggs", "Collect two moon-hen eggs", "Egg basket"),
				_step("breakfast_coffee", "Brew the extra-dark coffee", "Coffee machine"),
				_step("breakfast_cook", "Cook eggs to a heroic wobble", "Range"),
				_step("breakfast_plate", "Plate and ring the service bell", "Serving pass"),
			]
		),
		_task(
			"gadget", "Repair the Grapnel-9000", "WORKSHOP", "—", -1, 45, 12,
			[
				_step("gadget_open", "Open the scorched casing", "Grapnel casing"),
				_step("gadget_wires", "Reconnect the signal wires", "Wire matrix"),
				_step("gadget_battery", "Install a charged power cell", "Power cell"),
				_step("gadget_calibrate", "Calibrate launch pressure", "Calibration dial"),
				_step("gadget_close", "Seal and return the gadget", "Return cradle"),
			]
		),
		_task(
			"suit", "Restore Raccoon Man's suit", "WORKSHOP", "—", -1, 55, 14,
			[
				_step("suit_inspect", "Scan mud, burns and one dramatic tear", "Inspection scanner"),
				_step("suit_wash", "Wash on armored-delicates", "Suit washer"),
				_step("suit_dry", "Dry with cool ion air", "Drying chamber"),
				_step("suit_repair", "Patch the shoulder tear", "Repair bench"),
				_step("suit_polish", "Polish the chest emblem", "Polishing wheel"),
				_step("suit_display", "Return the suit to its display", "Suit display"),
			]
		),
		_task(
			"car", "Ready the Raccoon Roadster", "GARAGE", "11:30", 690, 40, 10,
			[
				_step("car_refuel", "Refill the stealth-fuel tank", "Fuel pump"),
				_step("car_tires", "Set all tires to 34 PSI", "Tire console"),
				_step("car_clean", "Remove last night's alley mud", "Wash controls"),
				_step("car_load", "Load spare smoke acorns", "Gadget trunk"),
			]
		),
		_task(
			"prison", "Cell service: Doctor Dreadful", "PRISON WING", "12:00", 720, 28, 8,
			[
				_step("cell_unlock", "Open the secure service hatch", "Hatch lock"),
				_step("cell_food", "Deliver the approved villain lunch", "Meal cart"),
				_step("cell_clean", "Sanitize the cell floor", "Cleaning station"),
				_step("cell_lock", "Lock and verify the service hatch", "Security panel"),
			]
		),
	]
	tasks_changed.emit()
	rewards_changed.emit(reputation, money)


func try_action(action_id: String) -> Dictionary:
	for task in tasks:
		var action_index := _action_index(task, action_id)
		if action_index < 0:
			continue
		if task.status == "complete":
			return {"status": "done", "message": "%s is already complete." % task.title}
		if action_index < task.step_index:
			return {"status": "done", "message": "Already handled — immaculate work."}
		if action_index > task.step_index:
			return {
				"status": "locked",
				"message": "Not quite yet. First: %s" % current_step(task).label,
			}
		if MINIGAME_ACTIONS.has(action_id):
			return {
				"status": "minigame",
				"kind": MINIGAME_ACTIONS[action_id],
				"action_id": action_id,
				"task_title": task.title,
				"step_label": current_step(task).label,
			}
		return _complete_step(task, action_id)
	return {"status": "unknown", "message": "That does not seem to be on today's list."}


func complete_minigame(action_id: String) -> Dictionary:
	for task in tasks:
		if task.status != "complete" and task.step_index < task.steps.size():
			if task.steps[task.step_index].action == action_id:
				return _complete_step(task, action_id)
	return {"status": "unknown", "message": "The job moved on while you were working."}


func update_deadlines(minute_of_day: int) -> void:
	var changed := false
	for task in tasks:
		if task.deadline >= 0 and task.status == "active" and minute_of_day > task.deadline:
			task.status = "late"
			task.late = true
			reputation = maxi(0, reputation - 2)
			deadline_missed.emit(task)
			changed = true
	if changed:
		tasks_changed.emit()
		rewards_changed.emit(reputation, money)


func current_step(task: Dictionary) -> Dictionary:
	if task.step_index >= task.steps.size():
		return {"action": "", "label": "Complete", "object": ""}
	return task.steps[task.step_index]


func get_progress_text(task: Dictionary) -> String:
	return "%d/%d" % [task.step_index, task.steps.size()]


func get_objective_actions() -> Array[String]:
	var result: Array[String] = []
	for task in tasks:
		if task.status != "complete" and task.step_index < task.steps.size():
			result.append(task.steps[task.step_index].action)
	return result


func get_save_data() -> Dictionary:
	var task_state := {}
	for task in tasks:
		task_state[task.id] = {
			"step_index": task.step_index,
			"status": task.status,
			"late": task.late,
		}
	return {
		"reputation": reputation,
		"money": money,
		"tasks": task_state,
	}


func apply_save_data(data: Dictionary) -> void:
	reputation = int(data.get("reputation", 12))
	money = int(data.get("money", 80))
	var state: Dictionary = data.get("tasks", {})
	for task in tasks:
		if state.has(task.id):
			var saved: Dictionary = state[task.id]
			task.step_index = clampi(int(saved.get("step_index", 0)), 0, task.steps.size())
			task.status = str(saved.get("status", "active"))
			task.late = bool(saved.get("late", false))
	tasks_changed.emit()
	rewards_changed.emit(reputation, money)


func _complete_step(task: Dictionary, action_id: String) -> Dictionary:
	task.step_index += 1
	var task_finished: bool = int(task.step_index) >= int(task.steps.size())
	var message := _completion_message(action_id)
	if task_finished:
		task.status = "complete"
		var money_reward: int = task.reward_money
		var rep_reward: int = task.reward_rep
		if task.late:
			money_reward = ceili(float(money_reward) * 0.65)
			rep_reward = maxi(1, rep_reward - 3)
		money += money_reward
		reputation += rep_reward
		message = "%s complete  ·  +$%d  +%d reputation" % [task.title, money_reward, rep_reward]
		task_completed.emit(task)
		rewards_changed.emit(reputation, money)
	tasks_changed.emit()
	return {
		"status": "complete" if task_finished else "advanced",
		"message": message,
		"action_id": action_id,
		"task_id": task.id,
		"task_finished": task_finished,
	}


func _task(
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


func _step(action: String, label: String, object_name: String) -> Dictionary:
	return {"action": action, "label": label, "object": object_name}


func _action_index(task: Dictionary, action_id: String) -> int:
	for i in range(task.steps.size()):
		if task.steps[i].action == action_id:
			return i
	return -1


func _completion_message(action_id: String) -> String:
	var messages := {
		"bath_temperature": "Water stabilized at a dignified 39°C.",
		"bath_products": "Cedar salts added. Subtle, heroic, pine-adjacent.",
		"bath_fill": "Water has reached the gold line. Do not dawdle.",
		"bath_stop": "Faucet stopped with three centimeters to spare.",
		"breakfast_eggs": "Two moon-hen eggs selected. Neither protested.",
		"breakfast_coffee": "Coffee brewed: dark enough to conceal an identity.",
		"breakfast_cook": "Eggs achieved peak heroic wobble.",
		"breakfast_plate": "Breakfast is plated and the silver bell has spoken.",
		"gadget_open": "Casing open. The scorch mark appears mostly theatrical.",
		"gadget_wires": "Signal wires reconnected in the correct dramatic order.",
		"gadget_battery": "Fresh power cell installed at 100% charge.",
		"gadget_calibrate": "Launch pressure calibrated. Probably roof-safe.",
		"gadget_close": "Grapnel-9000 sealed and mission-ready.",
		"suit_inspect": "Scan logged: mud, two burns, one suspicious claw mark.",
		"suit_wash": "Armored-delicates cycle complete.",
		"suit_dry": "Ion drying complete. Cape static: acceptable.",
		"suit_repair": "Shoulder tear patched with ballistic thread.",
		"suit_polish": "Chest emblem polished to a legally heroic shine.",
		"suit_display": "Suit restored to the display cradle.",
		"car_refuel": "Stealth-fuel topped up. Smells faintly of almonds.",
		"car_tires": "Tires balanced at 34 PSI.",
		"car_clean": "Alley mud removed. Two parking tickets recovered.",
		"car_load": "Smoke acorns loaded and counted twice.",
		"cell_unlock": "Service hatch open. Main containment remains secure.",
		"cell_food": "Villain lunch delivered: soup, bread, tiny spoon.",
		"cell_clean": "Cell floor sanitized under hostile literary criticism.",
		"cell_lock": "Hatch locked. Doctor Dreadful rates service four stars.",
	}
	return messages.get(action_id, "Job step complete.")

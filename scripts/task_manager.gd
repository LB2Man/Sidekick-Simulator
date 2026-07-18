extends Node

signal tasks_changed
signal task_completed(task: Dictionary)

const BathTask = preload("res://scripts/tasks/bath_task.gd")
const BreakfastTask = preload("res://scripts/tasks/breakfast_task.gd")
const GadgetTask = preload("res://scripts/tasks/gadget_task.gd")
const SuitTask = preload("res://scripts/tasks/suit_task.gd")
const CarTask = preload("res://scripts/tasks/car_task.gd")
const PrisonTask = preload("res://scripts/tasks/prison_task.gd")

var tasks: Array[Dictionary] = []
var minute_of_day := 450


func _ready() -> void:
	reset_day()


func reset_day() -> void:
	tasks = [
		BathTask.create(),
		BreakfastTask.create(),
		GadgetTask.create(),
		SuitTask.create(),
		CarTask.create(),
		PrisonTask.create(),
	]
	tasks_changed.emit()


func set_minute_of_day(value: int) -> void:
	var was_bath_available := minute_of_day >= 1200
	minute_of_day = value
	if was_bath_available != (minute_of_day >= 1200):
		tasks_changed.emit()


func is_task_available(task: Dictionary) -> bool:
	return task.status == "complete" or minute_of_day >= int(task.get("available_from", 0))


func try_action(action_id: String) -> Dictionary:
	for task in tasks:
		var action_index := _action_index(task, action_id)
		if action_index < 0:
			continue
		if task.status == "complete":
			return {"status": "done", "message": "%s is already complete." % task.title}
		if not is_task_available(task):
			return {
				"status": "locked",
				"message": "%s is prepared at %s so it stays warm for the master's return." % [task.title, task.availability_label],
			}
		if action_index < task.step_index:
			return {"status": "done", "message": "Already handled — immaculate work."}
		if action_index > task.step_index:
			return {
				"status": "locked",
				"message": "Not quite yet. First: %s" % current_step(task).label,
			}
		var step := current_step(task)
		var minigame_kind := str(step.get("minigame", ""))
		if not minigame_kind.is_empty():
			return {
				"status": "minigame",
				"kind": minigame_kind,
				"action_id": action_id,
				"task_title": task.title,
				"step_label": step.label,
			}
		return _complete_step(task, action_id)
	return {"status": "unknown", "message": "That does not seem to be on today's list."}


func complete_minigame(action_id: String) -> Dictionary:
	for task in tasks:
		if task.status != "complete" and task.step_index < task.steps.size():
			if task.steps[task.step_index].action == action_id:
				if not is_task_available(task):
					return {"status": "locked", "message": "%s is not available until %s." % [task.title, task.availability_label]}
				return _complete_step(task, action_id)
	return {"status": "unknown", "message": "The job moved on while you were working."}


func current_step(task: Dictionary) -> Dictionary:
	if task.step_index >= task.steps.size():
		return {"action": "", "label": "Complete", "object": ""}
	return task.steps[task.step_index]


func get_progress_text(task: Dictionary) -> String:
	return "%d/%d" % [task.step_index, task.steps.size()]


func get_objective_actions() -> Array[String]:
	var result: Array[String] = []
	for task in tasks:
		if task.status != "complete" and is_task_available(task) and task.step_index < task.steps.size():
			result.append(task.steps[task.step_index].action)
	return result


func reset_bath_fill() -> bool:
	for task in tasks:
		if task.id == "bath" and task.step_index > 0 and task.step_index < task.steps.size():
			if str(task.steps[task.step_index].action) == "bath_stop":
				task.step_index -= 1
				tasks_changed.emit()
				return true
	return false


func get_save_data() -> Dictionary:
	var task_state := {}
	for task in tasks:
		task_state[task.id] = {
			"step_index": task.step_index,
			"status": task.status,
		}
	return {"tasks": task_state}


func apply_save_data(data: Dictionary) -> void:
	var state: Dictionary = data.get("tasks", {})
	for task in tasks:
		if state.has(task.id):
			var saved: Dictionary = state[task.id]
			task.step_index = clampi(int(saved.get("step_index", 0)), 0, task.steps.size())
			task.status = str(saved.get("status", "active"))
			if task.status == "complete" and task.step_index < task.steps.size():
				task.status = "active"
	tasks_changed.emit()


func get_day_outcomes() -> Array[Dictionary]:
	var stories := {
		"bath": ["RECOVERED HERO SWEEPS ROOFTOPS", "A perfect 38°C bath, soothing salts and a warm towel kept Raccoon Man sharp through the night.", "WEARY VIGILANTE CUTS PATROL SHORT", "Without his recovery bath, aching muscles slowed the city's masked protector."],
		"breakfast": ["WELL-FED HERO OUTRUNS GETAWAY VAN", "A proper breakfast supplied enough energy for one sprint, two grapples and a dramatic landing.", "HUNGRY HERO MISTAKES SMOKE ACORN FOR SNACK", "Skipped breakfast left Raccoon Man distracted during the evening pursuit."],
		"gadget": ["GRAPNEL-9000 SAVES MUSEUM GALA", "A repaired launcher performed flawlessly above the museum's glass roof.", "FAULTY GRAPNEL LEAVES HERO ON AWNING", "Unfinished repairs turned a heroic entrance into an awkward wait for assistance."],
		"suit": ["RESTORED SUIT SHRUGS OFF LASER BLAST", "Clean armor and a reinforced shoulder kept the city's hero protected.", "TORN SUIT FORCES TACTICAL RETREAT", "Untended armor could not safely withstand Doctor Dreadful's latest contraption."],
		"car": ["RACCOON ROADSTER FOILS MIDNIGHT CHASE", "Fuel, balanced tires and fresh smoke acorns made the Roadster mission-ready.", "EMPTY ROADSTER FOUND BESIDE CURB", "The unprepared crime car failed before the chase could properly begin."],
		"prison": ["DOCTOR DREADFUL SECURE AFTER QUIET NIGHT", "A clean cell, proper meal and locked hatch kept the prisoner contained.", "VILLAIN EXPLOITS UNFINISHED CELL SERVICE", "An overlooked service hatch created one extremely preventable midnight emergency."],
	}
	var outcomes: Array[Dictionary] = []
	for task in tasks:
		var copy: Array = stories.get(str(task.id), [task.title, "Duty complete.", task.title, "Duty incomplete."])
		var complete: bool = task.status == "complete"
		outcomes.append({
			"task_id": task.id,
			"complete": complete,
			"headline": str(copy[0] if complete else copy[2]),
			"story": str(copy[1] if complete else copy[3]),
		})
	return outcomes


func _complete_step(task: Dictionary, action_id: String) -> Dictionary:
	var completed_step: Dictionary = task.steps[task.step_index]
	task.step_index += 1
	var task_finished: bool = int(task.step_index) >= int(task.steps.size())
	var message := str(completed_step.get("completion_message", "Job step complete."))
	var ai_confirmation := str(completed_step.get("ai_confirmation", ""))
	if ai_confirmation.is_empty():
		ai_confirmation = "Step logged. Your efficiency remains suspiciously comforting."
	if task_finished:
		task.status = "complete"
		message = "%s complete · Raccoon Man is better prepared for tonight." % task.title
		task_completed.emit(task)
	tasks_changed.emit()
	return {
		"status": "complete" if task_finished else "advanced",
		"message": message,
		"action_id": action_id,
		"task_id": task.id,
		"task_finished": task_finished,
		"ai_confirmation": ai_confirmation,
	}


func _action_index(task: Dictionary, action_id: String) -> int:
	for i in range(task.steps.size()):
		if task.steps[i].action == action_id:
			return i
	return -1

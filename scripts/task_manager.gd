extends Node

signal tasks_changed
signal task_completed(task: Dictionary)
signal deadline_missed(task: Dictionary)
signal rewards_changed(reputation: int, money: int)

const BathTask = preload("res://scripts/tasks/bath_task.gd")
const BreakfastTask = preload("res://scripts/tasks/breakfast_task.gd")
const GadgetTask = preload("res://scripts/tasks/gadget_task.gd")
const SuitTask = preload("res://scripts/tasks/suit_task.gd")
const CarTask = preload("res://scripts/tasks/car_task.gd")
const PrisonTask = preload("res://scripts/tasks/prison_task.gd")

var reputation := 12
var money := 80
var tasks: Array[Dictionary] = []


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
	var completed_step: Dictionary = task.steps[task.step_index]
	task.step_index += 1
	var task_finished: bool = int(task.step_index) >= int(task.steps.size())
	var message := str(completed_step.get("completion_message", "Job step complete."))
	var ai_confirmation := str(completed_step.get("ai_confirmation", ""))
	if ai_confirmation.is_empty():
		ai_confirmation = "Step logged. Your efficiency remains suspiciously comforting."
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
		"ai_confirmation": ai_confirmation,
	}


func _action_index(task: Dictionary, action_id: String) -> int:
	for i in range(task.steps.size()):
		if task.steps[i].action == action_id:
			return i
	return -1

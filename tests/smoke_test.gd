extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var tasks = scene.get_node_or_null("TaskManager")
	var world = scene.get_node_or_null("MansionAndLair")
	var player = scene.get_node_or_null("Player")
	var hud = scene.get_node_or_null("ButlerHUD")
	_check(tasks != null, "TaskManager is present")
	_check(world != null, "World builder is present")
	_check(player != null, "First-person player is present")
	_check(hud != null, "HUD is present")
	if tasks == null or world == null:
		_finish()
		return

	_check(tasks.tasks.size() == 6, "Six vertical-slice jobs are registered")
	_check(world.action_nodes.size() == 33, "All 32 task actions plus the task board exist")
	var task_list = hud.find_child("TaskList", true, false)
	var task_details = hud.find_child("TaskDetails", true, false)
	_check(task_list != null and task_list.get_child_count() == 6, "Today's service renders all six task cards")
	if task_list != null:
		_check(task_list.get_combined_minimum_size().y > 200.0, "Task cards have visible layout height")
	hud._set_task_panel_expanded(false)
	_check(task_details != null and not task_details.visible, "Today's service can be minimized")
	hud._set_task_panel_expanded(true)
	_check(task_details != null and task_details.visible, "Today's service can be expanded")
	tasks.set_minute_of_day(1200)
	for task in tasks.tasks:
		while task.status != "complete":
			var step: Dictionary = tasks.current_step(task)
			var result: Dictionary = tasks.try_action(str(step.action))
			if result.status == "minigame":
				result = tasks.complete_minigame(str(step.action))
			_check(result.status in ["advanced", "complete"], "%s advances via %s" % [str(task.title), str(step.action)])
			if not result.status in ["advanced", "complete"]:
				break

	var completed := 0
	for task in tasks.tasks:
		if task.status == "complete":
			completed += 1
	_check(completed == 6, "Every job can be completed from start to finish")
	_check(tasks.get_day_outcomes().size() == 6, "All duties contribute to the midnight newspaper")

	var state: Dictionary = tasks.get_save_data()
	tasks.reset_day()
	tasks.apply_save_data(state)
	var restored := 0
	for task in tasks.tasks:
		if task.status == "complete":
			restored += 1
	_check(restored == 6, "Task progression round-trips through save data")
	scene._end_day()
	_check(hud._newspaper_open, "Midnight pauses the day and opens the newspaper")
	_finish()


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures.append(description)
		push_error("FAIL: " + description)


func _finish() -> void:
	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED: ", _failures)
		quit(1)

extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var task_manager_script: Script = load("res://scripts/task_manager.gd")
	var task_manager: Node = task_manager_script.new()
	root.add_child(task_manager)

	var mansion_scene: PackedScene = load("res://scenes/mansion_world.tscn")
	var world: Node3D = mansion_scene.instantiate()
	root.add_child(world)

	_check(task_manager.tasks.size() == 6, "Six modular task definitions are registered")
	_check(_count_interactables(world) == 33, "Editable station scenes contain all expanded actions plus the task board")
	_check(
		world.get_node("BathStation").scene_file_path == "res://scenes/stations/bath_station.tscn",
		"Bath map is an editable scene instance"
	)
	_check(
		world.get_node("CarStation").scene_file_path == "res://scenes/stations/car_station.tscn",
		"Car map is an editable scene instance"
	)
	_check(str(task_manager.tasks[0].id) == "bath", "Bath task keeps its catalog order")
	_check(str(task_manager.tasks[4].id) == "car", "Car task keeps its catalog order")
	var locked_result: Dictionary = task_manager.try_action("bath_temperature")
	_check(locked_result.status == "locked", "Bath preparation is locked before 20:00")
	task_manager.set_minute_of_day(1200)
	_check(task_manager.is_task_available(task_manager.tasks[0]), "Bath preparation unlocks at 20:00")
	var temperature_result: Dictionary = task_manager.try_action("bath_temperature")
	_check(temperature_result.status == "minigame" and temperature_result.kind == "temperature", "Bath mixer opens the 38°C temperature interaction")
	task_manager.complete_minigame("bath_temperature")
	var fill_result: Dictionary = task_manager.try_action("bath_fill")
	_check(fill_result.status == "advanced", "Faucet starts the live bath fill")
	_check(task_manager.reset_bath_fill(), "Overflow rewinds the bath to the faucet step")

	for task in task_manager.tasks:
		while task.status != "complete":
			var step: Dictionary = task_manager.current_step(task)
			var result: Dictionary = task_manager.try_action(str(step.action))
			if result.status == "minigame":
				result = task_manager.complete_minigame(str(step.action))
			_check(
				result.status in ["advanced", "complete"],
				"%s advances through %s" % [str(task.id), str(step.action)]
			)
			if not result.status in ["advanced", "complete"]:
				break

	var completed_count := 0
	for task in task_manager.tasks:
		if task.status == "complete":
			completed_count += 1
	_check(completed_count == 6, "Every modular task completes")
	_check(task_manager.get_day_outcomes().size() == 6, "Midnight newspaper receives one outcome per duty")
	var save_data: Dictionary = task_manager.get_save_data()
	_check(not save_data.has("money") and not save_data.has("reputation"), "Task saves contain no money or reputation")
	_finish()


func _count_interactables(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name.begins_with("Interactable_"):
			count += 1
		count += _count_interactables(child)
	return count


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_failures.append(description)
		push_error("FAIL: " + description)


func _finish() -> void:
	if _failures.is_empty():
		print("TASK MODULE TEST PASSED")
		quit(0)
	else:
		print("TASK MODULE TEST FAILED: ", _failures)
		quit(1)

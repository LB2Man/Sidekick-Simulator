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
	_check(_count_interactables(world) == 28, "Editable station scenes contain every action plus the task board")
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

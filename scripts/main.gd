extends Node3D

const PlayerController = preload("res://scripts/player_controller.gd")
const TaskManager = preload("res://scripts/task_manager.gd")
const ButlerHUD = preload("res://scripts/butler_hud.gd")
const MansionWorldScene = preload("res://scenes/mansion_world.tscn")

const SAVE_PATH := "user://heros_butler_save.json"
const START_MINUTE := 450.0 # 07:30
const GAME_MINUTES_PER_SECOND := 0.5
const BATH_UNLOCK_MINUTE := 1200
const DAY_END_MINUTE := 1440.0
const BATH_FILL_RATE := 0.052
const BATH_TARGET_MIN := 0.74
const BATH_TARGET_MAX := 0.86
const TOWEL_WARM_SECONDS := 25.0

var _player: CharacterBody3D
var _tasks: Node
var _world: Node3D
var _hud: CanvasLayer
var _minute_of_day := START_MINUTE
var _last_displayed_minute := -1
var _selected_tool := 0
var _bath_filling := false
var _bath_water_level := 0.0
var _towel_warm_remaining := 0.0
var _day_ended := false
var _settings := {
	"subtitles": true,
	"high_contrast": false,
	"reduced_motion": false,
	"mouse_sensitivity": 0.0022,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_game()
	get_tree().paused = true
	_hud.set_paused(true)


func _process(delta: float) -> void:
	if not get_tree().paused:
		_update_bath_station(delta)
		_minute_of_day += delta * GAME_MINUTES_PER_SECOND
		if _minute_of_day >= DAY_END_MINUTE:
			_minute_of_day = DAY_END_MINUTE
			_end_day()
			return
		var whole_minute := floori(_minute_of_day)
		if whole_minute != _last_displayed_minute:
			_last_displayed_minute = whole_minute
			var was_locked: bool = int(_tasks.minute_of_day) < BATH_UNLOCK_MINUTE
			_tasks.set_minute_of_day(whole_minute)
			_update_clock()
			_hud.update_room(_world.get_room_for_position(_player.global_position))
			if was_locked and whole_minute >= BATH_UNLOCK_MINUTE:
				_hud.show_toast("20:00 · The evening bath stations are now available.", 5.0, true)


func _build_game() -> void:
	_tasks = TaskManager.new()
	_tasks.name = "TaskManager"
	add_child(_tasks)
	_tasks.task_completed.connect(_on_task_completed)
	_tasks.set_minute_of_day(floori(_minute_of_day))

	_world = get_node_or_null("MansionAndLair")
	if _world == null:
		# Fallback for isolated script tests; the main scene normally contains it.
		_world = MansionWorldScene.instantiate()
		add_child(_world)
	_world.action_requested.connect(_on_action_requested)

	_player = PlayerController.new()
	_player.name = "Player"
	_player.position = Vector3(0.0, 0.08, 2.0)
	add_child(_player)
	_player.set_spawn_point(_player.position)
	_player.focus_changed.connect(_on_focus_changed)
	_player.interaction_requested.connect(_on_player_interaction)
	_player.tool_selected.connect(_on_tool_selected)

	_hud = ButlerHUD.new()
	_hud.name = "ButlerHUD"
	add_child(_hud)
	_hud.configure(_tasks, _player, _world)
	_hud.pause_requested.connect(_set_paused)
	_hud.save_requested.connect(func(): save_game(false))
	_hud.load_requested.connect(load_game)
	_hud.restart_requested.connect(_restart_day)
	_hud.minigame_succeeded.connect(_on_minigame_succeeded)
	_hud.minigame_cancelled.connect(func(): _hud.show_toast("Work paused. The station will remember where you left off."))
	_hud.settings_changed.connect(_on_settings_changed)
	_hud.briefing_dismissed.connect(_on_briefing_dismissed)
	_hud.apply_settings(_settings)
	_apply_settings()
	_update_clock()


func _on_player_interaction(target: Node) -> void:
	if target.has_method("interact"):
		target.interact()


func _on_action_requested(action_id: String, _object_name: String) -> void:
	if action_id == "task_board":
		_hud.show_task_board()
		return
	if action_id == "bath_stop":
		_try_stop_bath_water()
		return
	if action_id == "bath_towel_ready" and _towel_warm_remaining > 0.0:
		_hud.show_toast("The towel needs %d more seconds on the warmer." % ceili(_towel_warm_remaining), 3.0)
		return
	var result: Dictionary = _tasks.try_action(action_id)
	match str(result.get("status", "unknown")):
		"minigame":
			_hud.start_minigame(result)
		"advanced", "complete":
			_complete_world_action(action_id, result)
		_:
			_hud.show_toast(str(result.get("message", "That is not ready yet.")), 3.0)


func _on_minigame_succeeded(action_id: String) -> void:
	var result: Dictionary = _tasks.complete_minigame(action_id)
	if str(result.get("status", "")) in ["advanced", "complete"]:
		_complete_world_action(action_id, result)


func _complete_world_action(action_id: String, result: Dictionary) -> void:
	_world.set_action_completed(action_id)
	if action_id == "bath_fill":
		_bath_filling = true
		_bath_water_level = 0.0
		_world.set_bath_water_level(_bath_water_level)
	elif action_id == "bath_stop":
		_hud.update_bath_fill(0.0, BATH_TARGET_MIN, BATH_TARGET_MAX)
	elif action_id == "bath_towel_warm":
		_towel_warm_remaining = TOWEL_WARM_SECONDS
		_world.set_bath_towel_state("warming")
	elif action_id == "bath_towel_ready":
		_world.set_bath_towel_state("ready")
	elif action_id == "bath_soap_refill":
		_world.set_bath_soap_filled(true)
	_hud.show_toast(str(result.message), 4.2, true)
	if not bool(result.get("task_finished", false)):
		_hud.show_subtitle(
			"H.A.R.O.L.D.",
			str(result.get("ai_confirmation", "Step logged. Your efficiency remains suspiciously comforting.")),
			4.0
		)
	save_game(true)


func _try_stop_bath_water() -> void:
	if not _bath_filling:
		if _tasks.minute_of_day < BATH_UNLOCK_MINUTE:
			_hud.show_toast("The recovery bath is prepared at 20:00 so it stays warm.", 3.0)
		else:
			_hud.show_toast("Turn on the faucet before using the stop lever.", 3.0)
		return
	if _bath_water_level < BATH_TARGET_MIN:
		_hud.show_toast("The water is below the gold line. Let it fill a little longer.", 2.7)
		return
	if _bath_water_level > BATH_TARGET_MAX:
		_reset_bath_fill("The water passed the safe band. The tub drained for another attempt.")
		return
	_bath_filling = false
	var result: Dictionary = _tasks.try_action("bath_stop")
	if str(result.get("status", "")) in ["advanced", "complete"]:
		_complete_world_action("bath_stop", result)


func _update_bath_station(delta: float) -> void:
	if _bath_filling:
		_bath_water_level = minf(1.0, _bath_water_level + delta * BATH_FILL_RATE)
		_world.set_bath_water_level(_bath_water_level)
		_hud.update_bath_fill(_bath_water_level, BATH_TARGET_MIN, BATH_TARGET_MAX)
		if _bath_water_level >= 1.0:
			_reset_bath_fill("The bath overflow sensor opened the drain. Turn the faucet on and try again.")
	if _towel_warm_remaining > 0.0:
		_towel_warm_remaining = maxf(0.0, _towel_warm_remaining - delta)
		_hud.update_towel_timer(_towel_warm_remaining)
		_world.set_bath_towel_heat(1.0 - (_towel_warm_remaining / TOWEL_WARM_SECONDS))
		if is_zero_approx(_towel_warm_remaining):
			_world.set_bath_towel_state("ready")
			_hud.show_toast("The towel warmer chimed. The towel is ready to collect.", 4.0, true)


func _reset_bath_fill(message: String) -> void:
	_bath_filling = false
	_bath_water_level = 0.0
	_tasks.reset_bath_fill()
	_world.set_action_completed("bath_fill", false)
	_world.set_action_completed("bath_stop", false)
	_world.set_bath_water_level(0.0)
	_hud.update_bath_fill(0.0, BATH_TARGET_MIN, BATH_TARGET_MAX)
	_hud.show_toast(message, 4.0)


func _on_task_completed(task: Dictionary) -> void:
	var completed_count := 0
	for entry in _tasks.tasks:
		if entry.status == "complete":
			completed_count += 1
	if completed_count >= _tasks.tasks.size():
		_hud.show_subtitle("H.A.R.O.L.D.", "Every support system is ready. Tonight's newspaper should contain unusually little property damage.", 7.0)
		_hud.show_toast("ALL DUTIES COMPLETE · Await the midnight newspaper.", 7.0, true)
	else:
		_hud.show_subtitle("H.A.R.O.L.D.", "%s signed off. %d duties remain." % [str(task.title), _tasks.tasks.size() - completed_count], 4.8)


func _on_focus_changed(prompt: String) -> void:
	_hud.set_interaction_prompt(prompt)


func _on_tool_selected(index: int) -> void:
	_selected_tool = index
	_hud.select_tool(index)
	var names := ["hands", "cleaning cloth", "toolkit", "scanner"]
	_hud.show_toast("Toolbelt: %s selected" % names[index], 1.7)


func _on_settings_changed(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_apply_settings()


func _apply_settings() -> void:
	_player.set_look_sensitivity(float(_settings.mouse_sensitivity))
	_player.set_reduced_motion(bool(_settings.reduced_motion))
	_hud.apply_settings(_settings)


func _on_briefing_dismissed() -> void:
	_set_paused(false)
	_hud.show_subtitle("H.A.R.O.L.D. · MANOR AI", "Good morning. Raccoon Man left mud on the ceiling again. Six duties await; choose your route.", 7.0)
	_hud.show_toast("Explore freely  ·  Gold markers identify each job's next step", 5.0)


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_hud.set_paused(value)


func _update_clock() -> void:
	var total := mini(floori(_minute_of_day), 1439)
	var hours := total / 60
	var minutes := total % 60
	var phase := "Morning"
	if hours >= 12 and hours < 17:
		phase = "Afternoon"
	elif hours >= 17 and hours < 21:
		phase = "Evening"
	elif hours >= 21 or hours < 5:
		phase = "Night"
	_hud.update_clock("%02d:%02d" % [hours, minutes], phase)


func save_game(silent: bool = false) -> void:
	var data := {
		"version": 2,
		"minute_of_day": _minute_of_day,
		"tasks": _tasks.get_save_data(),
		"bath_state": {
			"filling": _bath_filling,
			"water_level": _bath_water_level,
			"towel_warm_remaining": _towel_warm_remaining,
		},
		"player_position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"player_rotation_y": _player.rotation.y,
		"selected_tool": _selected_tool,
		"settings": _settings,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		if not silent:
			_hud.show_toast("Save failed: the manor ledger is unavailable.")
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	if not silent:
		_hud.show_toast("Game saved to the private manor ledger.", 3.0, true)


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_hud.show_toast("No saved ledger exists yet. Press F5 to create one.", 3.5)
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_hud.show_toast("The saved ledger could not be opened.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_hud.show_toast("The saved ledger is unreadable.")
		return
	var data: Dictionary = parsed
	_minute_of_day = clampf(float(data.get("minute_of_day", START_MINUTE)), START_MINUTE, DAY_END_MINUTE)
	var saved_tasks: Dictionary = data.get("tasks", {}).duplicate(true)
	if int(data.get("version", 1)) < 2:
		# The old four-step bath cannot map safely onto the new nine-step evening workflow.
		var task_entries: Dictionary = saved_tasks.get("tasks", {})
		task_entries.erase("bath")
		saved_tasks["tasks"] = task_entries
	_tasks.apply_save_data(saved_tasks)
	_tasks.set_minute_of_day(floori(_minute_of_day))
	var bath_state: Dictionary = data.get("bath_state", {})
	_bath_filling = bool(bath_state.get("filling", false))
	_bath_water_level = clampf(float(bath_state.get("water_level", 0.0)), 0.0, 1.0)
	_towel_warm_remaining = maxf(0.0, float(bath_state.get("towel_warm_remaining", 0.0)))
	var pos: Array = data.get("player_position", [0.0, 0.08, 2.0])
	if pos.size() >= 3:
		_player.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	_player.rotation.y = float(data.get("player_rotation_y", 0.0))
	_selected_tool = clampi(int(data.get("selected_tool", 0)), 0, 3)
	_settings = data.get("settings", _settings).duplicate(true)
	_apply_settings()
	_hud.select_tool(_selected_tool)
	_sync_world_state()
	_update_clock()
	_last_displayed_minute = floori(_minute_of_day)
	if _minute_of_day >= DAY_END_MINUTE:
		_end_day()
		return
	_hud.show_toast("Saved game loaded. Welcome back to the manor.", 3.5, true)


func _sync_world_state() -> void:
	for task in _tasks.tasks:
		for i in range(task.steps.size()):
			_world.set_action_completed(str(task.steps[i].action), i < task.step_index)
	_world.set_bath_water_level(_bath_water_level)
	_world.set_bath_soap_filled(_is_action_complete("bath_soap_refill"))
	if _is_action_complete("bath_towel_ready"):
		_world.set_bath_towel_state("ready")
	elif _is_action_complete("bath_towel_warm"):
		_world.set_bath_towel_state("ready" if _towel_warm_remaining <= 0.0 else "warming")
	else:
		_world.set_bath_towel_state("empty")
	if _towel_warm_remaining > 0.0:
		_hud.update_towel_timer(_towel_warm_remaining)
	if _bath_filling:
		_hud.update_bath_fill(_bath_water_level, BATH_TARGET_MIN, BATH_TARGET_MAX)


func _is_action_complete(action_id: String) -> bool:
	for task in _tasks.tasks:
		for i in range(mini(int(task.step_index), int(task.steps.size()))):
			if str(task.steps[i].action) == action_id:
				return true
	return false


func _end_day() -> void:
	if _day_ended:
		return
	_day_ended = true
	_bath_filling = false
	_tasks.set_minute_of_day(1440)
	_hud.update_clock("00:00", "MIDNIGHT EDITION")
	_set_paused(true)
	_hud.show_newspaper(_tasks.get_day_outcomes())


func _restart_day() -> void:
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

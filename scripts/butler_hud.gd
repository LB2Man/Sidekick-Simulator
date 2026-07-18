extends CanvasLayer

signal pause_requested(paused: bool)
signal save_requested
signal load_requested
signal restart_requested
signal minigame_succeeded(action_id: String)
signal minigame_cancelled
signal settings_changed(settings: Dictionary)
signal briefing_dismissed

const Minimap = preload("res://scripts/minimap.gd")

const INK := Color("0a111a")
const PANEL := Color("101b27ed")
const PANEL_LIGHT := Color("1b2b38f2")
const CYAN := Color("6ce9ef")
const GOLD := Color("ffd166")
const TEXT := Color("eef4f2")
const MUTED := Color("9fb2ba")
const GREEN := Color("6dd6a0")
const RED := Color("ff7b70")

var _task_manager: Node
var _player: Node3D
var _world: Node3D

var _root: Control
var _clock_label: Label
var _phase_label: Label
var _room_label: Label
var _bath_status_label: Label
var _task_list: VBoxContainer
var _task_details: VBoxContainer
var _task_heading: Label
var _task_hint: Label
var _task_toggle_button: Button
var _task_scroll: ScrollContainer
var _interaction_panel: PanelContainer
var _interaction_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _subtitle_panel: PanelContainer
var _subtitle_speaker: Label
var _subtitle_label: Label
var _minimap: Control
var _tool_slots: Array[PanelContainer] = []
var _task_panel: PanelContainer
var _task_panel_expanded := true

var _pause_overlay: Control
var _board_overlay: Control
var _briefing_overlay: Control
var _minigame_overlay: Control
var _minigame_title: Label
var _minigame_instruction: Label
var _minigame_content: VBoxContainer
var _timing_bar: ProgressBar
var _timing_target: ColorRect
var _temperature_label: Label
var _temperature_hint: Label
var _bath_monitor: PanelContainer
var _bath_fill_label: Label
var _bath_fill_bar: ProgressBar
var _towel_timer_label: Label
var _newspaper_overlay: Control
var _newspaper_panel: PanelContainer
var _newspaper_articles: GridContainer

var _toast_time := 0.0
var _subtitle_time := 0.0
var _paused := false
var _board_open := false
var _briefing_open := true
var _minigame_open := false
var _minigame_kind := ""
var _minigame_action := ""
var _temperature_value := 32
var _timing_value := 0.0
var _timing_direction := 1.0
var _timing_misses := 0
var _wire_sequence := [0, 2, 1]
var _wire_progress := 0
var _newspaper_open := false
var _fill_monitor_active := false
var _towel_monitor_active := false

var subtitles_enabled := true
var high_contrast := false
var reduced_motion := false
var mouse_sensitivity := 0.0022


func configure(task_manager: Node, player: Node3D, world: Node3D) -> void:
	_task_manager = task_manager
	_player = player
	_world = world
	_build_ui()
	_minimap.set_sources(_player, _world, _task_manager)
	_task_manager.tasks_changed.connect(refresh_tasks)
	refresh_tasks()
	show_briefing()


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast_panel.modulate.a = clampf(_toast_time * 2.0, 0.0, 1.0)
	if _subtitle_time > 0.0:
		_subtitle_time -= delta
		_subtitle_panel.modulate.a = clampf(_subtitle_time * 2.0, 0.0, 1.0)
	if _minigame_open and _minigame_kind == "timing":
		_timing_value += delta * 58.0 * _timing_direction
		if _timing_value >= 100.0:
			_timing_value = 100.0
			_timing_direction = -1.0
		elif _timing_value <= 0.0:
			_timing_value = 0.0
			_timing_direction = 1.0
		_timing_bar.value = _timing_value


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _minigame_open:
		if event.physical_keycode in [KEY_SPACE, KEY_E] and _minigame_kind == "timing":
			_attempt_timing()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ESCAPE:
			_close_minigame(false)
			get_viewport().set_input_as_handled()
		return
	if _newspaper_open:
		return
	if _briefing_open:
		return
	if event.physical_keycode == KEY_ESCAPE:
		if _board_open:
			_close_board()
		else:
			pause_requested.emit(not _paused)
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_TAB or event.physical_keycode == KEY_B:
		if _board_open:
			_close_board()
		else:
			show_task_board()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_T:
		_toggle_task_panel()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F5:
		save_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F9:
		load_requested.emit()
		get_viewport().set_input_as_handled()


func update_clock(clock_text: String, phase_text: String) -> void:
	_clock_label.text = clock_text
	_phase_label.text = phase_text.to_upper()
	if is_instance_valid(_bath_status_label):
		var hour := int(clock_text.substr(0, 2))
		var bath_open := hour >= 20 and phase_text != "MIDNIGHT EDITION"
		_bath_status_label.text = "BATH OPEN" if bath_open else "BATH AT 20:00"
		_bath_status_label.add_theme_color_override("font_color", GREEN if bath_open else GOLD)


func update_room(room_name: String) -> void:
	_room_label.text = room_name


func set_interaction_prompt(text: String) -> void:
	_interaction_label.text = text
	_interaction_panel.visible = not text.is_empty() and not _paused and not _minigame_open and not _board_open


func show_toast(message: String, duration: float = 3.2, success: bool = false) -> void:
	_toast_label.text = ("✓  " if success else "") + message
	_toast_label.add_theme_color_override("font_color", GREEN if success else TEXT)
	_toast_panel.modulate.a = 1.0
	_toast_time = duration


func show_subtitle(speaker: String, text: String, duration: float = 5.0) -> void:
	if not subtitles_enabled:
		return
	_subtitle_speaker.text = speaker.to_upper()
	_subtitle_label.text = text
	_subtitle_panel.modulate.a = 1.0
	_subtitle_time = duration


func set_paused(value: bool) -> void:
	_paused = value
	_pause_overlay.visible = value and not _board_open and not _minigame_open and not _briefing_open and not _newspaper_open
	_interaction_panel.visible = false if value else not _interaction_label.text.is_empty()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED


func show_briefing() -> void:
	_briefing_open = true
	_briefing_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_task_board() -> void:
	_board_open = true
	_board_overlay.visible = true
	_populate_board()
	pause_requested.emit(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func start_minigame(data: Dictionary) -> void:
	_minigame_open = true
	_minigame_kind = str(data.kind)
	_minigame_action = str(data.action_id)
	_minigame_overlay.visible = true
	_minigame_title.text = str(data.task_title).to_upper()
	_minigame_instruction.text = str(data.step_label)
	_clear_container(_minigame_content)
	pause_requested.emit(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match _minigame_kind:
		"wires":
			_build_wire_minigame()
		"temperature":
			_build_temperature_minigame()
		_:
			_build_timing_minigame()


func update_bath_fill(level: float, target_min: float, target_max: float) -> void:
	_fill_monitor_active = level > 0.0
	_bath_fill_bar.value = clampf(level, 0.0, 1.0) * 100.0
	if level < target_min:
		_bath_fill_label.text = "BATH LEVEL  %d%%  ·  FILLING TO GOLD BAND" % roundi(maxf(level, 0.0) * 100.0)
		_bath_fill_label.add_theme_color_override("font_color", CYAN)
	elif level <= target_max:
		_bath_fill_label.text = "BATH LEVEL  %d%%  ·  STOP NOW" % roundi(level * 100.0)
		_bath_fill_label.add_theme_color_override("font_color", GOLD)
	else:
		_bath_fill_label.text = "BATH LEVEL  %d%%  ·  TOO HIGH" % roundi(level * 100.0)
		_bath_fill_label.add_theme_color_override("font_color", RED)
	_refresh_bath_monitor()


func update_towel_timer(seconds_remaining: float) -> void:
	_towel_monitor_active = seconds_remaining > 0.0
	_towel_timer_label.text = "TOWEL WARMER  ·  %d SECONDS" % ceili(maxf(seconds_remaining, 0.0))
	_refresh_bath_monitor()


func show_newspaper(outcomes: Array[Dictionary]) -> void:
	_newspaper_open = true
	_newspaper_overlay.visible = true
	_pause_overlay.visible = false
	_interaction_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_container(_newspaper_articles)
	var completed := 0
	for outcome in outcomes:
		if bool(outcome.complete):
			completed += 1
		var article := PanelContainer.new()
		article.custom_minimum_size = Vector2(390.0, 112.0)
		article.add_theme_stylebox_override("panel", _panel_style(Color("eee3c9"), Color("76684f"), 1, 4))
		_newspaper_articles.add_child(article)
		var margin := MarginContainer.new()
		_margins(margin, 12, 9)
		article.add_child(margin)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 4)
		margin.add_child(copy)
		var headline := _label(str(outcome.headline), 14, Color("17130f"))
		headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(headline)
		var story := _label(str(outcome.story), 11, Color("4a4032"))
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(story)
	var banner := _newspaper_panel.find_child("EditionBanner", true, false) as Label
	if banner:
		banner.text = "%d OF 6 SUPPORT SYSTEMS READY · RACCOON MAN'S NIGHT IN REVIEW" % completed
	_newspaper_panel.scale = Vector2(0.58, 0.58) if not reduced_motion else Vector2.ONE
	_newspaper_panel.rotation = deg_to_rad(-3.0) if not reduced_motion else 0.0
	_newspaper_panel.modulate.a = 0.35 if not reduced_motion else 1.0
	if not reduced_motion:
		_newspaper_panel.pivot_offset = _newspaper_panel.size * 0.5
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
		tween.tween_property(_newspaper_panel, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_newspaper_panel, "rotation", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_newspaper_panel, "modulate:a", 1.0, 0.45)


func refresh_tasks() -> void:
	if not is_instance_valid(_task_list):
		return
	_clear_container(_task_list)
	for task in _task_manager.tasks:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(330.0, 58.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var complete: bool = task.status == "complete"
		var available: bool = _task_manager.is_task_available(task)
		card.add_theme_stylebox_override("panel", _panel_style(Color("12202bd9"), GREEN if complete else (Color("37515d") if available else Color("66747a")), 1, 8))
		var margin := MarginContainer.new()
		_margins(margin, 10, 7)
		card.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		margin.add_child(box)
		var top := HBoxContainer.new()
		box.add_child(top)
		var title := _label(("✓  " if complete else "") + str(task.title), 14, GREEN if complete else TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(title)
		var availability := _label(str(task.availability_label), 12, GREEN if available else GOLD)
		top.add_child(availability)
		var step_text := "All duties complete" if complete else (str(_task_manager.current_step(task).label) if available else "Available at %s to stay warm" % str(task.availability_label))
		var step := _label("%s  ·  %s  ·  %s" % [str(task.room), _task_manager.get_progress_text(task), step_text], 11, MUTED)
		step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(step)
		_task_list.add_child(card)
	if is_instance_valid(_task_heading) and not _task_panel_expanded:
		_task_heading.text = "DUTIES · %d" % _task_manager.tasks.size()


func select_tool(index: int) -> void:
	for i in range(_tool_slots.size()):
		_tool_slots[i].add_theme_stylebox_override("panel", _panel_style(Color("24303bdf"), GOLD if i == index else Color("465766"), 2 if i == index else 1, 7))


func apply_settings(settings: Dictionary) -> void:
	subtitles_enabled = bool(settings.get("subtitles", true))
	high_contrast = bool(settings.get("high_contrast", false))
	reduced_motion = bool(settings.get("reduced_motion", false))
	mouse_sensitivity = float(settings.get("mouse_sensitivity", 0.0022))
	_minimap.set_high_contrast(high_contrast)
	_task_panel.add_theme_stylebox_override("panel", _panel_style(Color("050b10f5") if high_contrast else PANEL, Color.WHITE if high_contrast else Color("395563"), 2, 11))


func _build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_status_bar()
	_build_task_panel()
	_build_minimap()
	_build_interaction_prompt()
	_build_toolbelt()
	_build_bath_monitor()
	_build_toast()
	_build_subtitles()
	_build_pause_overlay()
	_build_board_overlay()
	_build_briefing_overlay()
	_build_minigame_overlay()
	_build_newspaper_overlay()


func _build_status_bar() -> void:
	var bar := PanelContainer.new()
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.offset_left = -210.0
	bar.offset_right = 210.0
	bar.offset_top = 18.0
	bar.offset_bottom = 76.0
	bar.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("426775"), 2, 10))
	_root.add_child(bar)
	var margin := MarginContainer.new()
	_margins(margin, 16, 7)
	bar.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var crest := _label("◉", 26, GOLD)
	row.add_child(crest)
	var time_box := VBoxContainer.new()
	time_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(time_box)
	_clock_label = _label("07:30", 20, TEXT)
	_phase_label = _label("MORNING", 10, CYAN)
	time_box.add_child(_clock_label)
	time_box.add_child(_phase_label)
	var location_box := VBoxContainer.new()
	location_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(location_box)
	var location_caption := _label("CURRENT ROOM", 10, MUTED)
	location_box.add_child(location_caption)
	_room_label = _label("GRAND FOYER", 15, TEXT)
	location_box.add_child(_room_label)
	_bath_status_label = _label("BATH AT 20:00", 12, GOLD)
	_bath_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_bath_status_label)


func _build_task_panel() -> void:
	_task_panel = PanelContainer.new()
	_task_panel.name = "TaskPanel"
	_task_panel.offset_left = 18.0
	_task_panel.offset_top = 18.0
	_task_panel.offset_right = 390.0
	_task_panel.anchor_bottom = 0.0
	_task_panel.offset_bottom = 470.0
	_task_panel.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("395563"), 2, 11))
	_root.add_child(_task_panel)
	var margin := MarginContainer.new()
	_margins(margin, 12, 12)
	_task_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var heading_row := HBoxContainer.new()
	box.add_child(heading_row)
	_task_heading = _label("TODAY'S SERVICE", 18, GOLD)
	_task_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(_task_heading)
	_task_hint = _label("TAB · BOARD", 10, MUTED)
	_task_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_row.add_child(_task_hint)
	_task_toggle_button = _button("[T]  –")
	_task_toggle_button.name = "TaskToggle"
	_task_toggle_button.tooltip_text = "Minimize today's service panel"
	_task_toggle_button.custom_minimum_size = Vector2(58.0, 34.0)
	_task_toggle_button.add_theme_font_size_override("font_size", 11)
	_task_toggle_button.pressed.connect(_toggle_task_panel)
	heading_row.add_child(_task_toggle_button)

	_task_details = VBoxContainer.new()
	_task_details.name = "TaskDetails"
	_task_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_details.add_theme_constant_override("separation", 8)
	box.add_child(_task_details)
	var separator := HSeparator.new()
	separator.modulate = Color("5e7782")
	_task_details.add_child(separator)
	_task_scroll = ScrollContainer.new()
	_task_scroll.name = "TaskScroll"
	_task_scroll.custom_minimum_size = Vector2(340.0, 240.0)
	_task_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_task_details.add_child(_task_scroll)
	_task_list = VBoxContainer.new()
	_task_list.name = "TaskList"
	_task_list.custom_minimum_size.x = 330.0
	_task_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_list.add_theme_constant_override("separation", 7)
	_task_scroll.add_child(_task_list)


func _toggle_task_panel() -> void:
	_set_task_panel_expanded(not _task_panel_expanded)


func _set_task_panel_expanded(expanded: bool) -> void:
	_task_panel_expanded = expanded
	_task_details.visible = expanded
	_task_hint.visible = expanded
	_task_toggle_button.text = "[T]  –" if expanded else "[T]  +"
	_task_toggle_button.tooltip_text = "Minimize today's service panel" if expanded else "Expand today's service panel"
	if expanded:
		_task_panel.anchor_bottom = 0.0
		_task_panel.offset_right = 390.0
		_task_panel.offset_bottom = 470.0
		_task_heading.text = "TODAY'S SERVICE"
	else:
		_task_panel.anchor_bottom = 0.0
		_task_panel.offset_right = 268.0
		_task_panel.offset_bottom = 154.0
		_task_heading.text = "DUTIES · %d" % _task_manager.tasks.size()


func _build_minimap() -> void:
	var holder := PanelContainer.new()
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.offset_left = -292.0
	holder.offset_right = -18.0
	holder.offset_top = 18.0
	holder.offset_bottom = 218.0
	holder.add_theme_stylebox_override("panel", _panel_style(Color("081017e6"), Color("395563"), 1, 10))
	_root.add_child(holder)
	var margin := MarginContainer.new()
	_margins(margin, 6, 6)
	holder.add_child(margin)
	_minimap = Minimap.new()
	margin.add_child(_minimap)


func _build_interaction_prompt() -> void:
	var crosshair := _label("·", 34, Color("ffffffc9"))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-5.0, -24.0)
	crosshair.add_theme_constant_override("outline_size", 6)
	crosshair.add_theme_color_override("font_outline_color", INK)
	_root.add_child(crosshair)
	_interaction_panel = PanelContainer.new()
	_interaction_panel.anchor_left = 0.5
	_interaction_panel.anchor_right = 0.5
	_interaction_panel.anchor_top = 0.5
	_interaction_panel.anchor_bottom = 0.5
	_interaction_panel.offset_left = -250.0
	_interaction_panel.offset_right = 250.0
	_interaction_panel.offset_top = 48.0
	_interaction_panel.offset_bottom = 98.0
	_interaction_panel.add_theme_stylebox_override("panel", _panel_style(Color("0c1720e8"), GOLD, 2, 8))
	_interaction_panel.visible = false
	_root.add_child(_interaction_panel)
	_interaction_label = _label("", 16, TEXT)
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_panel.add_child(_interaction_label)


func _build_toolbelt() -> void:
	var row := HBoxContainer.new()
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = -270.0
	row.offset_right = 270.0
	row.offset_top = -70.0
	row.offset_bottom = -16.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	var tools := ["1  HANDS", "2  CLOTH", "3  TOOLKIT", "4  SCANNER"]
	for i in range(tools.size()):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(126.0, 48.0)
		slot.add_theme_stylebox_override("panel", _panel_style(Color("24303bdf"), GOLD if i == 0 else Color("465766"), 2 if i == 0 else 1, 7))
		var label := _label(tools[i], 12, TEXT if i == 0 else MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)
		row.add_child(slot)
		_tool_slots.append(slot)


func _build_bath_monitor() -> void:
	_bath_monitor = PanelContainer.new()
	_bath_monitor.anchor_left = 1.0
	_bath_monitor.anchor_right = 1.0
	_bath_monitor.anchor_top = 1.0
	_bath_monitor.anchor_bottom = 1.0
	_bath_monitor.offset_left = -408.0
	_bath_monitor.offset_right = -18.0
	_bath_monitor.offset_top = -164.0
	_bath_monitor.offset_bottom = -86.0
	_bath_monitor.add_theme_stylebox_override("panel", _panel_style(Color("0b1821ef"), GOLD, 1, 8))
	_bath_monitor.visible = false
	_root.add_child(_bath_monitor)
	var margin := MarginContainer.new()
	_margins(margin, 12, 8)
	_bath_monitor.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	_bath_fill_label = _label("BATH LEVEL", 11, CYAN)
	box.add_child(_bath_fill_label)
	_bath_fill_bar = ProgressBar.new()
	_bath_fill_bar.min_value = 0.0
	_bath_fill_bar.max_value = 100.0
	_bath_fill_bar.show_percentage = false
	_bath_fill_bar.custom_minimum_size.y = 14.0
	_bath_fill_bar.add_theme_stylebox_override("background", _panel_style(Color("111c25"), Color("445765"), 1, 4))
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.set_corner_radius_all(4)
	_bath_fill_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bath_fill_bar)
	_towel_timer_label = _label("TOWEL WARMER", 11, GOLD)
	box.add_child(_towel_timer_label)


func _refresh_bath_monitor() -> void:
	_bath_monitor.visible = _fill_monitor_active or _towel_monitor_active
	_bath_fill_label.visible = _fill_monitor_active
	_bath_fill_bar.visible = _fill_monitor_active
	_towel_timer_label.visible = _towel_monitor_active


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.offset_left = -350.0
	_toast_panel.offset_right = 350.0
	_toast_panel.offset_top = 90.0
	_toast_panel.offset_bottom = 142.0
	_toast_panel.add_theme_stylebox_override("panel", _panel_style(Color("101c24f0"), Color("4a6570"), 1, 9))
	_toast_panel.modulate.a = 0.0
	_root.add_child(_toast_panel)
	_toast_label = _label("", 16, TEXT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)


func _build_subtitles() -> void:
	_subtitle_panel = PanelContainer.new()
	_subtitle_panel.anchor_left = 0.5
	_subtitle_panel.anchor_right = 0.5
	_subtitle_panel.anchor_top = 1.0
	_subtitle_panel.anchor_bottom = 1.0
	_subtitle_panel.offset_left = -360.0
	_subtitle_panel.offset_right = 360.0
	_subtitle_panel.offset_top = -160.0
	_subtitle_panel.offset_bottom = -90.0
	_subtitle_panel.add_theme_stylebox_override("panel", _panel_style(Color("060b10e8"), Color("4d6670"), 1, 7))
	_subtitle_panel.modulate.a = 0.0
	_root.add_child(_subtitle_panel)
	var margin := MarginContainer.new()
	_margins(margin, 14, 8)
	_subtitle_panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	_subtitle_speaker = _label("H.A.R.O.L.D.", 11, GOLD)
	box.add_child(_subtitle_speaker)
	_subtitle_label = _label("", 15, TEXT)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle_label)


func _build_pause_overlay() -> void:
	_pause_overlay = _overlay()
	_pause_overlay.visible = false
	_root.add_child(_pause_overlay)
	var panel := _center_panel(_pause_overlay, Vector2(520, 570), GOLD)
	var box := _panel_vbox(panel, 28, 22)
	var title := _label("SERVICE PAUSED", 31, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var flavor := _label("The manor will keep its secrets for a moment.", 14, MUTED)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(flavor)
	var resume := _button("RESUME DUTIES")
	resume.pressed.connect(func(): pause_requested.emit(false))
	box.add_child(resume)
	var save := _button("SAVE GAME  ·  F5")
	save.pressed.connect(func(): save_requested.emit())
	box.add_child(save)
	var load := _button("LOAD GAME  ·  F9")
	load.pressed.connect(func(): load_requested.emit())
	box.add_child(load)
	var divider := HSeparator.new()
	box.add_child(divider)
	var settings_heading := _label("ACCESSIBILITY & CONTROLS", 13, CYAN)
	box.add_child(settings_heading)
	var subtitle_toggle := CheckButton.new()
	subtitle_toggle.text = "Subtitles"
	subtitle_toggle.button_pressed = true
	subtitle_toggle.toggled.connect(func(value: bool): subtitles_enabled = value; _emit_settings())
	box.add_child(subtitle_toggle)
	var contrast_toggle := CheckButton.new()
	contrast_toggle.text = "High-contrast interface"
	contrast_toggle.toggled.connect(func(value: bool): high_contrast = value; apply_settings(_settings_dict()); _emit_settings())
	box.add_child(contrast_toggle)
	var motion_toggle := CheckButton.new()
	motion_toggle.text = "Reduced camera motion"
	motion_toggle.toggled.connect(func(value: bool): reduced_motion = value; _emit_settings())
	box.add_child(motion_toggle)
	var sensitivity_row := HBoxContainer.new()
	box.add_child(sensitivity_row)
	var sens_label := _label("Mouse sensitivity", 13, TEXT)
	sens_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensitivity_row.add_child(sens_label)
	var slider := HSlider.new()
	slider.min_value = 0.0008
	slider.max_value = 0.005
	slider.step = 0.0001
	slider.value = mouse_sensitivity
	slider.custom_minimum_size.x = 210.0
	slider.value_changed.connect(func(value: float): mouse_sensitivity = value; _emit_settings())
	sensitivity_row.add_child(slider)
	var restart := _button("RESTART DAY")
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)


func _build_board_overlay() -> void:
	_board_overlay = _overlay()
	_board_overlay.visible = false
	_root.add_child(_board_overlay)
	var panel := _center_panel(_board_overlay, Vector2(920, 620), CYAN)
	var box := _panel_vbox(panel, 28, 24)
	var title_row := HBoxContainer.new()
	box.add_child(title_row)
	var title := _label("THE DAILY SERVICE LEDGER", 28, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := _button("CLOSE  ·  TAB")
	close.custom_minimum_size = Vector2(150.0, 42.0)
	close.pressed.connect(_close_board)
	title_row.add_child(close)
	var intro := _label("Duties prepare Raccoon Man for his night patrol. The recovery bath opens at 20:00 so it remains warm.", 14, MUTED)
	box.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var ledger := VBoxContainer.new()
	ledger.name = "Ledger"
	ledger.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ledger.add_theme_constant_override("separation", 10)
	scroll.add_child(ledger)


func _build_briefing_overlay() -> void:
	_briefing_overlay = _overlay(Color("04080df4"))
	_root.add_child(_briefing_overlay)
	var panel := _center_panel(_briefing_overlay, Vector2(780, 560), GOLD)
	var box := _panel_vbox(panel, 42, 36)
	var kicker := _label("A COZY FIRST-PERSON SERVICE SIMULATION", 12, CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	var title := _label("HERO'S BUTLER\nSIMULATOR", 46, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", INK)
	box.add_child(title)
	var line := HSeparator.new()
	box.add_child(line)
	var description := _label("Raccoon Man is out saving the city. You have the harder job: keeping his mansion, suit, gadgets, roadster, breakfast and prisoners in working order.", 18, TEXT)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var controls := _label("WASD MOVE   ·   MOUSE LOOK   ·   E INTERACT   ·   SHIFT SPRINT   ·   CTRL CROUCH   ·   SPACE JUMP\nT MINIMIZE DUTIES   ·   TAB TASK BOARD   ·   1–4 TOOLBELT   ·   ESC PAUSE", 13, MUTED)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(controls)
	var start := _button("ENTER THE MANOR")
	start.custom_minimum_size.y = 58.0
	start.pressed.connect(_dismiss_briefing)
	box.add_child(start)


func _build_minigame_overlay() -> void:
	_minigame_overlay = _overlay(Color("071017e8"))
	_minigame_overlay.visible = false
	_root.add_child(_minigame_overlay)
	var panel := _center_panel(_minigame_overlay, Vector2(700, 470), GOLD)
	var box := _panel_vbox(panel, 34, 30)
	_minigame_title = _label("PRECISION WORK", 27, GOLD)
	_minigame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_minigame_title)
	_minigame_instruction = _label("", 17, TEXT)
	_minigame_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_minigame_instruction)
	var divider := HSeparator.new()
	box.add_child(divider)
	_minigame_content = VBoxContainer.new()
	_minigame_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_minigame_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_minigame_content.add_theme_constant_override("separation", 18)
	box.add_child(_minigame_content)
	var cancel := _button("CANCEL  ·  ESC")
	cancel.pressed.connect(func(): _close_minigame(false))
	box.add_child(cancel)


func _build_newspaper_overlay() -> void:
	_newspaper_overlay = _overlay(Color("020407f2"))
	_newspaper_overlay.visible = false
	_root.add_child(_newspaper_overlay)
	_newspaper_panel = _center_panel(_newspaper_overlay, Vector2(940, 680), Color("c9b889"))
	_newspaper_panel.add_theme_stylebox_override("panel", _panel_style(Color("e8dcc0"), Color("6d6049"), 3, 3))
	var box := _panel_vbox(_newspaper_panel, 24, 18)
	var masthead := _label("THE MASKED CITY GAZETTE", 30, Color("17130f"))
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(masthead)
	var edition := _label("MIDNIGHT EDITION · SERVICE RESULTS", 12, Color("5b4e3b"))
	edition.name = "EditionBanner"
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(edition)
	var rule := HSeparator.new()
	box.add_child(rule)
	_newspaper_articles = GridContainer.new()
	_newspaper_articles.columns = 2
	_newspaper_articles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_newspaper_articles.add_theme_constant_override("h_separation", 10)
	_newspaper_articles.add_theme_constant_override("v_separation", 8)
	box.add_child(_newspaper_articles)
	var restart := _button("BEGIN A NEW DAY")
	restart.custom_minimum_size.y = 44.0
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)


func _build_temperature_minigame() -> void:
	_temperature_value = 32
	var hint := _label("Turn the cold and hot mixer wheels until the thermometer reads exactly 38°C.", 14, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(hint)
	_temperature_label = _label("32°C", 44, CYAN)
	_temperature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(_temperature_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	_minigame_content.add_child(row)
	var cold := _button("COLD  −2°")
	cold.custom_minimum_size = Vector2(190, 78)
	cold.add_theme_color_override("font_color", CYAN)
	cold.pressed.connect(_adjust_temperature.bind(-2))
	row.add_child(cold)
	var hot := _button("HOT  +2°")
	hot.custom_minimum_size = Vector2(190, 78)
	hot.add_theme_color_override("font_color", RED)
	hot.pressed.connect(_adjust_temperature.bind(2))
	row.add_child(hot)
	_temperature_hint = _label("Perfect temperature: 38°C", 13, GOLD)
	_temperature_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(_temperature_hint)
	var confirm := _button("LOCK TEMPERATURE")
	confirm.pressed.connect(_confirm_temperature)
	_minigame_content.add_child(confirm)


func _adjust_temperature(change: int) -> void:
	_temperature_value = clampi(_temperature_value + change, 20, 50)
	_temperature_label.text = "%d°C" % _temperature_value
	_temperature_label.add_theme_color_override("font_color", GOLD if _temperature_value == 38 else (CYAN if _temperature_value < 38 else RED))
	_temperature_hint.text = "Perfect temperature reached." if _temperature_value == 38 else ("Too cold · add hot water" if _temperature_value < 38 else "Too hot · add cold water")


func _confirm_temperature() -> void:
	if _temperature_value == 38:
		_close_minigame(true)
	else:
		_temperature_hint.text = "The master requires exactly 38°C. Adjust the mixer first."
		_temperature_hint.add_theme_color_override("font_color", RED)


func _build_wire_minigame() -> void:
	_wire_progress = 0
	var diagnostic := _label("H.A.R.O.L.D. DIAGNOSTIC:  CYAN  →  MAGENTA  →  GOLD", 16, CYAN)
	diagnostic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(diagnostic)
	var instruction := _label("Reconnect the wire terminals in the shown order.", 14, MUTED)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(instruction)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_minigame_content.add_child(row)
	var names := ["CYAN", "GOLD", "MAGENTA"]
	var colors := [CYAN, GOLD, Color("e56ecf")]
	for i in range(3):
		var button := _button(names[i])
		button.custom_minimum_size = Vector2(160, 90)
		button.add_theme_color_override("font_color", colors[i])
		button.pressed.connect(_wire_pressed.bind(i))
		row.add_child(button)


func _build_timing_minigame() -> void:
	_timing_value = 0.0
	_timing_direction = 1.0
	_timing_misses = 0
	var label_text := "Stop the heat inside the gold zone." if _minigame_action == "breakfast_cook" else "Lock the calibration needle inside the gold zone."
	var hint := _label(label_text + "  Press SPACE or E.", 15, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(hint)
	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(550.0, 74.0)
	_minigame_content.add_child(bar_holder)
	_timing_bar = ProgressBar.new()
	_timing_bar.position = Vector2(0.0, 20.0)
	_timing_bar.size = Vector2(550.0, 34.0)
	_timing_bar.min_value = 0.0
	_timing_bar.max_value = 100.0
	_timing_bar.show_percentage = false
	_timing_bar.add_theme_stylebox_override("background", _panel_style(Color("111c25"), Color("445765"), 1, 6))
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.set_corner_radius_all(5)
	_timing_bar.add_theme_stylebox_override("fill", fill)
	bar_holder.add_child(_timing_bar)
	_timing_target = ColorRect.new()
	_timing_target.position = Vector2(236.5, 16.0)
	_timing_target.size = Vector2(82.5, 42.0)
	_timing_target.color = Color("ffd1667a")
	_timing_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_holder.add_child(_timing_target)
	var misses := _label("Attempts are unlimited. Precision earns dignity.", 12, MUTED)
	misses.name = "Misses"
	misses.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_content.add_child(misses)


func _attempt_timing() -> void:
	if _timing_value >= 43.0 and _timing_value <= 58.0:
		_close_minigame(true)
	else:
		var was_early := _timing_value < 43.0
		_timing_misses += 1
		_timing_value = 0.0
		_timing_direction = 1.0
		var misses := _minigame_content.get_node_or_null("Misses") as Label
		if misses:
			misses.text = "A little %s. Resetting…  Misses: %d" % ["early" if was_early else "late", _timing_misses]
			misses.add_theme_color_override("font_color", RED)


func _wire_pressed(index: int) -> void:
	if index == _wire_sequence[_wire_progress]:
		_wire_progress += 1
		if _wire_progress >= _wire_sequence.size():
			_close_minigame(true)
	else:
		_wire_progress = 0
		show_toast("Circuit chirped disapprovingly. Sequence reset.", 2.2)


func _close_minigame(success: bool) -> void:
	var action := _minigame_action
	_minigame_open = false
	_minigame_overlay.visible = false
	_clear_container(_minigame_content)
	if success:
		minigame_succeeded.emit(action)
	else:
		minigame_cancelled.emit()
	if not _board_open:
		pause_requested.emit(false)


func _populate_board() -> void:
	var scroll := _board_overlay.find_child("Ledger", true, false) as VBoxContainer
	if not scroll:
		return
	_clear_container(scroll)
	for task in _task_manager.tasks:
		var card := PanelContainer.new()
		var complete: bool = task.status == "complete"
		var available: bool = _task_manager.is_task_available(task)
		card.add_theme_stylebox_override("panel", _panel_style(Color("13212be8"), GREEN if complete else Color("47616c"), 1, 8))
		scroll.add_child(card)
		var margin := MarginContainer.new()
		_margins(margin, 14, 10)
		card.add_child(margin)
		var row := HBoxContainer.new()
		margin.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var title := _label(("✓  " if complete else "") + str(task.title), 17, GREEN if complete else TEXT)
		info.add_child(title)
		var steps_text := ""
		for i in range(task.steps.size()):
			var marker := "✓" if i < task.step_index else ("➤" if i == task.step_index else "·")
			steps_text += "%s %s%s" % [marker, str(task.steps[i].label), "   " if i < task.steps.size() - 1 else ""]
		var steps := _label(steps_text, 11, MUTED)
		steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(steps)
		var schedule_text := "%s\n%s" % [str(task.room), str(task.availability_label)]
		if not available:
			schedule_text += "\nLOCKED"
		var schedule := _label(schedule_text, 12, GOLD if available else MUTED)
		schedule.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(schedule)


func _close_board() -> void:
	_board_open = false
	_board_overlay.visible = false
	pause_requested.emit(false)


func _dismiss_briefing() -> void:
	_briefing_open = false
	_briefing_overlay.visible = false
	briefing_dismissed.emit()


func _emit_settings() -> void:
	settings_changed.emit(_settings_dict())


func _settings_dict() -> Dictionary:
	return {
		"subtitles": subtitles_enabled,
		"high_contrast": high_contrast,
		"reduced_motion": reduced_motion,
		"mouse_sensitivity": mouse_sensitivity,
	}


func _overlay(color: Color = Color("03080dcc")) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = color
	overlay.add_child(dim)
	return overlay


func _center_panel(parent: Control, panel_size: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -panel_size * 0.5
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color("101a23fa"), border, 2, 14))
	parent.add_child(panel)
	return panel


func _panel_vbox(panel: PanelContainer, horizontal: int, vertical: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	_margins(margin, horizontal, vertical)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box


func _panel_style(background: Color, border: Color, width: int = 1, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("00000088")
	style.shadow_size = 7
	return style


func _label(value: String, size_value: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color("253846"), Color("49616c"), 1, 7))
	button.add_theme_stylebox_override("hover", _panel_style(Color("315362"), CYAN, 2, 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("1c2d36"), GOLD, 2, 7))
	return button


func _margins(container: MarginContainer, horizontal: int, vertical: int) -> void:
	container.add_theme_constant_override("margin_left", horizontal)
	container.add_theme_constant_override("margin_right", horizontal)
	container.add_theme_constant_override("margin_top", vertical)
	container.add_theme_constant_override("margin_bottom", vertical)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

extends Control

var player: Node3D
var world: Node3D
var task_manager: Node
var high_contrast := false

const WORLD_MIN := Vector2(-27.0, -11.0)
const WORLD_MAX := Vector2(27.0, 28.0)

const ROOMS := [
	{"name": "KITCHEN", "rect": Rect2(-27.0, -11.0, 19.0, 18.0), "color": Color("755f4b")},
	{"name": "LOBBY", "rect": Rect2(-8.0, -11.0, 16.0, 18.0), "color": Color("65413f")},
	{"name": "BATH", "rect": Rect2(8.0, -11.0, 19.0, 18.0), "color": Color("426b72")},
	{"name": "PRISON", "rect": Rect2(-27.0, 7.0, 19.0, 21.0), "color": Color("4c3b41")},
	{"name": "GARAGE", "rect": Rect2(-8.0, 7.0, 16.0, 21.0), "color": Color("31444c")},
	{"name": "WORKSHOP", "rect": Rect2(8.0, 7.0, 19.0, 21.0), "color": Color("245763")},
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260.0, 188.0)


func set_sources(player_node: Node3D, world_node: Node3D, tasks_node: Node) -> void:
	player = player_node
	world = world_node
	task_manager = tasks_node
	queue_redraw()


func set_high_contrast(value: bool) -> void:
	high_contrast = value
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_style_box(_background_style(), outer)
	var map_rect := Rect2(9.0, 24.0, size.x - 18.0, size.y - 33.0)
	for room in ROOMS:
		var room_rect: Rect2 = room.rect
		var p1 := _world_to_map(room_rect.position, map_rect)
		var p2 := _world_to_map(room_rect.end, map_rect)
		var rect := Rect2(p1, p2 - p1)
		var color: Color = room.color
		if high_contrast:
			color = color.lightened(0.16)
		draw_rect(rect.grow(-1.0), color, true)
		draw_rect(rect.grow(-1.0), Color("d8c18e") if high_contrast else Color("77919b"), false, 1.4)
		var label_position := rect.position + Vector2(5.0, 13.0)
		draw_string(ThemeDB.fallback_font, label_position, room.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("e8edf0b8"))

	if is_instance_valid(world) and is_instance_valid(task_manager):
		for action_id in task_manager.get_objective_actions():
			var objective_world: Vector3 = world.get_action_position(action_id)
			var objective := _world_to_map(Vector2(objective_world.x, objective_world.z), map_rect)
			draw_circle(objective, 4.5, Color("ffd166"))
			draw_arc(objective, 7.0, 0.0, TAU, 20, Color("fff0b2a0"), 1.2)

	if is_instance_valid(player):
		var player_point := _world_to_map(Vector2(player.global_position.x, player.global_position.z), map_rect)
		var heading := -player.rotation.y
		var forward := Vector2(sin(heading), -cos(heading))
		var right := forward.rotated(2.2)
		var left := forward.rotated(-2.2)
		var points := PackedVector2Array([
			player_point + forward * 8.0,
			player_point + right * 5.0,
			player_point + left * 5.0,
		])
		draw_colored_polygon(points, Color("6cf4ff") if not high_contrast else Color.WHITE)

	draw_string(ThemeDB.fallback_font, Vector2(10.0, 16.0), "MANOR FLOORPLAN  ·  GOLD = NEXT STEP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b9d7dc"))


func _world_to_map(world_point: Vector2, map_rect: Rect2) -> Vector2:
	var normalized := Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_point.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_point.y)
	)
	return map_rect.position + normalized * map_rect.size


func _background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b131be8")
	style.border_color = Color("d7a84c") if high_contrast else Color("426775")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	return style

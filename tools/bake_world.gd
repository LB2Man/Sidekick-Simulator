extends SceneTree

const WorldBuilder = preload("res://scripts/world_builder.gd")
const COMPONENTS := [
	{"name": "MansionShell", "path": "res://scenes/world/mansion_shell.tscn", "script": ""},
	{"name": "Lobby", "path": "res://scenes/world/lobby.tscn", "script": "res://scripts/world/lobby.gd"},
	{"name": "BreakfastStation", "path": "res://scenes/stations/breakfast_station.tscn", "script": "res://scripts/world/breakfast_station.gd"},
	{"name": "BathStation", "path": "res://scenes/stations/bath_station.tscn", "script": "res://scripts/world/bath_station.gd"},
	{"name": "GadgetStation", "path": "res://scenes/stations/gadget_station.tscn", "script": "res://scripts/world/gadget_station.gd"},
	{"name": "SuitStation", "path": "res://scenes/stations/suit_station.tscn", "script": "res://scripts/world/suit_station.gd"},
	{"name": "CarStation", "path": "res://scenes/stations/car_station.tscn", "script": "res://scripts/world/car_station.gd"},
	{"name": "PrisonStation", "path": "res://scenes/stations/prison_station.tscn", "script": "res://scripts/world/prison_station.gd"},
]


func _initialize() -> void:
	call_deferred("_bake_world")


func _bake_world() -> void:
	for component in COMPONENTS:
		if not _bake_component(component):
			quit(1)
			return
	print("Baked editable component scenes: ", COMPONENTS.size())
	print("The authored mansion_world.tscn composition was left unchanged.")
	quit(0)


func _bake_component(component: Dictionary) -> bool:
	var builder: Node3D = WorldBuilder.new()
	var script_path := str(component.script)
	if script_path.is_empty():
		builder.build_shell_scene()
	else:
		builder.build_station_scene(load(script_path))

	var scene_root := Node3D.new()
	scene_root.name = str(component.name)
	for child in builder.get_children():
		builder.remove_child(child)
		scene_root.add_child(child)
	builder.free()
	var saved := _save_scene(scene_root, str(component.path))
	scene_root.free()
	return saved


func _save_scene(scene_root: Node, output_path: String) -> bool:
	var output_directory := ProjectSettings.globalize_path(output_path.get_base_dir())
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create scene directory: %s" % error_string(directory_error))
		return false
	_assign_scene_owner(scene_root, scene_root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(scene_root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [output_path, error_string(pack_error)])
		return false
	var save_error := ResourceSaver.save(packed, output_path)
	if save_error != OK:
		push_error("Could not save %s: %s" % [output_path, error_string(save_error)])
		return false
	print("Saved editable scene: ", output_path)
	return true


func _assign_scene_owner(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_assign_scene_owner(child, scene_owner)

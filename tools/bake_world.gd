extends SceneTree

const OUTPUT_PATH := "res://scenes/mansion_world.tscn"


func _initialize() -> void:
	call_deferred("_bake_world")


func _bake_world() -> void:
	var world_script: Script = load("res://scripts/world_builder.gd")
	var world: Node3D = world_script.new()
	world.name = "MansionAndLair"
	world.baked_scene = true
	world.build_world()
	root.add_child(world)
	_assign_scene_owner(world, world)

	var output_directory := ProjectSettings.globalize_path("res://scenes")
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create scenes directory: %s" % error_string(directory_error))
		quit(1)
		return

	var packed := PackedScene.new()
	var pack_error := packed.pack(world)
	if pack_error != OK:
		push_error("Could not pack mansion world: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save mansion world: %s" % error_string(save_error))
		quit(1)
		return

	print("Baked editable mansion scene: ", OUTPUT_PATH)
	print("Root editor nodes: ", world.get_child_count())
	print("Interactable editor nodes: ", world.action_nodes.size())
	quit(0)


func _assign_scene_owner(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_assign_scene_owner(child, scene_owner)

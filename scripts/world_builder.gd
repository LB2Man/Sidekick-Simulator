extends Node3D

signal action_requested(action_id: String, object_name: String)

const Interactable = preload("res://scripts/interactable.gd")
const Lobby = preload("res://scripts/world/lobby.gd")
const BreakfastStation = preload("res://scripts/world/breakfast_station.gd")
const BathStation = preload("res://scripts/world/bath_station.gd")
const GadgetStation = preload("res://scripts/world/gadget_station.gd")
const SuitStation = preload("res://scripts/world/suit_station.gd")
const CarStation = preload("res://scripts/world/car_station.gd")
const PrisonStation = preload("res://scripts/world/prison_station.gd")

const C_STONE := Color("27313d")
const C_WALL := Color("34303b")
const C_WALL_WARM := Color("514449")
const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_INK := Color("11151d")

@export var baked_scene := false

var action_nodes: Dictionary = {}
var room_centers := {
	"LOBBY": Vector2(0.0, -2.0),
	"KITCHEN": Vector2(-17.0, -2.0),
	"BATHROOM": Vector2(17.0, -2.0),
	"WORKSHOP": Vector2(17.0, 16.0),
	"GARAGE": Vector2(0.0, 18.0),
	"PRISON WING": Vector2(-17.0, 16.0),
}

var _architecture: Node3D
var _props: Node3D
var _interactables: Node3D
var _lights: Node3D


func _ready() -> void:
	if baked_scene:
		_index_baked_world()
	else:
		build_world()


func build_world() -> void:
	name = "MansionAndLair"
	_initialize_folders()
	_build_environment()
	_build_shell()
	Lobby.build(self)
	BreakfastStation.build(self)
	BathStation.build(self)
	GadgetStation.build(self)
	SuitStation.build(self)
	CarStation.build(self)
	PrisonStation.build(self)


func build_shell_scene() -> void:
	_initialize_folders()
	_build_environment()
	_build_shell()


func build_station_scene(station_script: Script) -> void:
	_initialize_folders()
	station_script.build(self)


func _initialize_folders() -> void:
	_architecture = _folder("Architecture")
	_props = _folder("Props")
	_interactables = _folder("Interactables")
	_lights = _folder("Lighting")


func _index_baked_world() -> void:
	action_nodes.clear()
	_index_interactables(self)
	if action_nodes.is_empty():
		push_error("Editable mansion scene does not contain any interactables.")


func _index_interactables(parent: Node) -> void:
	for item in parent.get_children():
		if item.has_method("get_interaction_text") and not str(item.action_id).is_empty():
			action_nodes[str(item.action_id)] = item
			if item.has_signal("activated") and not item.activated.is_connected(_on_interactable_activated):
				item.activated.connect(_on_interactable_activated)
		_index_interactables(item)


func set_action_completed(action_id: String, completed: bool = true) -> void:
	if action_nodes.has(action_id):
		action_nodes[action_id].set_completed(completed)


func set_bath_water_level(level: float) -> void:
	var water := get_node_or_null("Props/BathWater") as Node3D
	if not is_instance_valid(water):
		return
	var amount := clampf(level, 0.0, 1.0)
	water.visible = amount > 0.01
	water.position.y = 0.10 + amount * 0.27
	water.scale.y = maxf(0.15, amount * 4.0)


func set_bath_towel_state(state: String) -> void:
	var towel := get_node_or_null("Props/TowelOnWarmer") as Node3D
	if is_instance_valid(towel):
		towel.visible = state in ["warming", "ready"]
	set_bath_towel_heat(1.0 if state == "ready" else 0.0)


func set_bath_towel_heat(progress: float) -> void:
	var mesh := get_node_or_null("Props/TowelOnWarmer/Mesh") as MeshInstance3D
	if not is_instance_valid(mesh):
		return
	if not mesh.has_meta("unique_heat_material"):
		mesh.material_override = mesh.material_override.duplicate()
		mesh.set_meta("unique_heat_material", true)
	var material := mesh.material_override as StandardMaterial3D
	if is_instance_valid(material):
		material.emission_enabled = true
		material.emission = Color("ffd9a0")
		material.emission_energy_multiplier = lerpf(0.2, 1.2, clampf(progress, 0.0, 1.0))


func set_bath_soap_filled(filled: bool) -> void:
	var soap := get_node_or_null("Props/ShowerSoapCube") as Node3D
	if is_instance_valid(soap):
		soap.visible = filled


func get_action_position(action_id: String) -> Vector3:
	if action_nodes.has(action_id):
		return action_nodes[action_id].global_position
	return Vector3.ZERO


func get_room_for_position(world_position: Vector3) -> String:
	if world_position.z < 7.0:
		if world_position.x < -8.0:
			return "KITCHEN"
		if world_position.x > 8.0:
			return "BATHROOM"
		return "LOBBY"
	if world_position.x < -8.0:
		return "PRISON WING"
	if world_position.x > 8.0:
		return "WORKSHOP"
	return "GARAGE"


# Room modules use this small construction API and do not need access to the
# world builder's orchestration or indexing internals.
func get_props_root() -> Node3D:
	return _props


func add_interactable(
	action_id: String,
	object_name: String,
	hint: String,
	room: String,
	size: Vector3,
	color: Color,
	world_position: Vector3,
	shape_kind: String = "box"
) -> Node:
	return _make_interactable(action_id, object_name, hint, room, size, color, world_position, shape_kind)


func add_block(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	size: Vector3,
	color: Color,
	with_collision: bool = true,
	emission_energy: float = 0.0
) -> MeshInstance3D:
	return _block(parent, object_name, world_position, size, color, with_collision, emission_energy)


func add_cylinder(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	radius: float,
	height: float,
	color: Color,
	with_collision: bool = false,
	emission_energy: float = 0.0,
	rotation_degrees_value: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	return _cylinder(
		parent, object_name, world_position, radius, height, color,
		with_collision, emission_energy, rotation_degrees_value
	)


func add_sphere(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	radius: float,
	color: Color,
	emissive: bool = false,
	emission_energy: float = 0.0
) -> MeshInstance3D:
	return _sphere(parent, object_name, world_position, radius, color, emissive, emission_energy)


func add_room_light(world_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	_add_light(world_position, color, energy, range_value)


func add_room_title(text: String, world_position: Vector3, rotation_value: Vector3, color: Color) -> void:
	_room_title(text, world_position, rotation_value, color)


func add_raccoon_emblem(world_position: Vector3, rotation_value: Vector3, scale_value: float) -> void:
	_raccoon_emblem(world_position, rotation_value, scale_value)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "RainyNightEnvironment"
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("060b17")
	sky_material.sky_horizon_color = Color("16263e")
	sky_material.ground_horizon_color = Color("101823")
	sky_material.ground_bottom_color = Color("05070b")
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8090ad")
	environment.ambient_light_energy = 0.22
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 0.75
	environment.fog_enabled = true
	environment.fog_light_color = Color("152136")
	environment.fog_light_energy = 0.36
	environment.fog_density = 0.004
	world_environment.environment = environment
	add_child(world_environment)

	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	moon.light_color = Color("9eb9e8")
	moon.light_energy = 0.42
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 72.0
	_lights.add_child(moon)


func _build_shell() -> void:
	_block(_architecture, "Foundation", Vector3(0.0, -0.22, 8.5), Vector3(54.0, 0.44, 39.0), C_STONE)
	_block(_architecture, "FrontWall", Vector3(0.0, 2.35, -11.0), Vector3(54.0, 4.7, 0.45), C_WALL)
	_block(_architecture, "BackWall", Vector3(0.0, 2.35, 28.0), Vector3(54.0, 4.7, 0.45), C_STONE)
	_block(_architecture, "WestWall", Vector3(-27.0, 2.35, 8.5), Vector3(0.45, 4.7, 39.0), C_WALL)
	_block(_architecture, "EastWall", Vector3(27.0, 2.35, 8.5), Vector3(0.45, 4.7, 39.0), C_WALL)

	# Room floors make navigation readable at a glance.
	_block(_architecture, "LobbyFloor", Vector3(0.0, 0.025, -2.0), Vector3(15.5, 0.05, 17.5), Color("503c35"), false)
	_block(_architecture, "KitchenFloor", Vector3(-17.5, 0.03, -2.0), Vector3(18.3, 0.06, 17.5), Color("73675a"), false)
	_block(_architecture, "BathroomFloor", Vector3(17.5, 0.035, -2.0), Vector3(18.3, 0.07, 17.5), Color("46616a"), false)
	_block(_architecture, "WorkshopFloor", Vector3(17.5, 0.04, 17.5), Vector3(18.3, 0.08, 20.3), Color("1b3038"), false)
	_block(_architecture, "GarageFloor", Vector3(0.0, 0.04, 17.5), Vector3(15.5, 0.08, 20.3), Color("252c32"), false)
	_block(_architecture, "PrisonFloor", Vector3(-17.5, 0.04, 17.5), Vector3(18.3, 0.08, 20.3), Color("22272e"), false)

	# Vertical dividers, each split around a generous doorway.
	for side in [-8.0, 8.0]:
		_block(_architecture, "FrontDividerA", Vector3(side, 2.35, -7.0), Vector3(0.36, 4.7, 8.0), C_WALL_WARM)
		_block(_architecture, "FrontDividerB", Vector3(side, 2.35, 4.0), Vector3(0.36, 4.7, 4.0), C_WALL_WARM)
		_block(_architecture, "FrontDoorHeader", Vector3(side, 4.1, -1.0), Vector3(0.38, 1.2, 4.0), C_WALL_WARM)
		_block(_architecture, "BackDividerA", Vector3(side, 2.35, 10.0), Vector3(0.36, 4.7, 5.5), C_STONE)
		_block(_architecture, "BackDividerB", Vector3(side, 2.35, 23.5), Vector3(0.36, 4.7, 8.5), C_STONE)
		_block(_architecture, "BackDoorHeader", Vector3(side, 4.1, 15.0), Vector3(0.38, 1.2, 4.5), C_STONE)

	# Side rooms change function at z=7, with a doorway cut into each divider.
	_block(_architecture, "WestCrossA", Vector3(-23.0, 2.35, 7.0), Vector3(8.0, 4.7, 0.36), C_WALL)
	_block(_architecture, "WestCrossB", Vector3(-11.0, 2.35, 7.0), Vector3(6.0, 4.7, 0.36), C_WALL)
	_block(_architecture, "WestCrossHeader", Vector3(-17.0, 4.1, 7.0), Vector3(4.0, 1.2, 0.38), C_WALL)
	_block(_architecture, "EastCrossA", Vector3(11.0, 2.35, 7.0), Vector3(6.0, 4.7, 0.36), C_WALL)
	_block(_architecture, "EastCrossB", Vector3(23.0, 2.35, 7.0), Vector3(8.0, 4.7, 0.36), C_WALL)
	_block(_architecture, "EastCrossHeader", Vector3(17.0, 4.1, 7.0), Vector3(4.0, 1.2, 0.38), C_WALL)

	# Ceiling panels preserve the indoor mood while leaving tech strips between them.
	for center in [
		Vector3(0.0, 4.72, -2.0), Vector3(-17.5, 4.72, -2.0), Vector3(17.5, 4.72, -2.0),
		Vector3(0.0, 4.72, 17.5), Vector3(-17.5, 4.72, 17.5), Vector3(17.5, 4.72, 17.5)
	]:
		var panel_size := Vector3(15.4, 0.2, 17.2) if absf(center.z + 2.0) < 0.1 else Vector3(15.4, 0.2, 20.0)
		_block(_architecture, "CeilingPanel", center, panel_size, Color("17191f"))

	# Brass trim ties old mansion architecture to the secret base.
	for x in [-26.6, -8.2, 8.2, 26.6]:
		_block(_architecture, "BrassTrim", Vector3(x, 0.34, 8.5), Vector3(0.08, 0.12, 38.0), C_GOLD, false, 0.6)
	for z in [-10.65, 6.8, 27.65]:
		_block(_architecture, "BrassTrim", Vector3(0.0, 0.34, z), Vector3(53.0, 0.12, 0.08), C_GOLD, false, 0.6)


func _make_interactable(
	action_id: String,
	object_name: String,
	hint: String,
	room: String,
	size: Vector3,
	color: Color,
	world_position: Vector3,
	shape_kind: String = "box"
) -> Node:
	var item := Interactable.new()
	item.configure(action_id, object_name, hint, room, size, color, shape_kind)
	item.position = world_position
	item.activated.connect(_on_interactable_activated)
	_interactables.add_child(item)
	action_nodes[action_id] = item
	return item


func _on_interactable_activated(action_id: String, object_name: String) -> void:
	action_requested.emit(action_id, object_name)


func _folder(folder_name: String) -> Node3D:
	var result := Node3D.new()
	result.name = folder_name
	add_child(result)
	return result


func _block(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	size: Vector3,
	color: Color,
	with_collision: bool = true,
	emission_energy: float = 0.0
) -> MeshInstance3D:
	var body: Node3D
	if with_collision:
		var static_body := StaticBody3D.new()
		static_body.collision_layer = 1
		static_body.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		static_body.add_child(collision)
		body = static_body
	else:
		body = Node3D.new()
	body.name = _unique_child_name(parent, object_name)
	body.position = world_position
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, 0.0 if emission_energy <= 0.0 else 0.18, 0.78, emission_energy)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh_instance)
	return mesh_instance


func _cylinder(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	radius: float,
	height: float,
	color: Color,
	with_collision: bool = false,
	emission_energy: float = 0.0,
	rotation_degrees_value: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var body: Node3D
	if with_collision:
		var static_body := StaticBody3D.new()
		static_body.collision_layer = 1
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		static_body.add_child(collision)
		body = static_body
	else:
		body = Node3D.new()
	body.name = _unique_child_name(parent, object_name)
	body.position = world_position
	body.rotation_degrees = rotation_degrees_value
	parent.add_child(body)
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	instance.mesh = mesh
	instance.material_override = _material(color, 0.3, 0.45, emission_energy)
	body.add_child(instance)
	return instance


func _sphere(
	parent: Node,
	object_name: String,
	world_position: Vector3,
	radius: float,
	color: Color,
	emissive: bool = false,
	emission_energy: float = 0.0
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = _unique_child_name(parent, object_name)
	instance.position = world_position
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.material_override = _material(color, 0.15, 0.35, emission_energy if emissive else 0.0)
	parent.add_child(instance)
	return instance


func _material(color: Color, metallic: float, roughness: float, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material


func _add_light(world_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = _unique_child_name(_lights, "RoomLight")
	light.position = world_position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.omni_attenuation = 1.1
	light.shadow_enabled = true
	_lights.add_child(light)


func _room_title(text: String, world_position: Vector3, rotation_value: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = _unique_child_name(_props, "RoomTitle")
	label.text = text
	label.position = world_position
	label.rotation_degrees = rotation_value
	label.font_size = 34
	label.outline_size = 10
	label.modulate = color
	label.outline_modulate = Color("090b11e8")
	label.no_depth_test = false
	_props.add_child(label)


func _raccoon_emblem(world_position: Vector3, rotation_value: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.name = "RaccoonEmblem"
	root.position = world_position
	root.rotation_degrees = rotation_value
	root.scale = Vector3.ONE * scale_value
	_props.add_child(root)
	_sphere(root, "Mask", Vector3.ZERO, 0.72, Color("51616c"))
	for x in [-0.36, 0.36]:
		_sphere(root, "EyePatch", Vector3(x, 0.08, -0.58), 0.22, C_INK)
		_sphere(root, "EyeGlow", Vector3(x, 0.08, -0.76), 0.065, C_CYAN, true, 2.0)
	_sphere(root, "Nose", Vector3(0.0, -0.28, -0.68), 0.12, C_INK)


func _unique_child_name(parent: Node, requested_name: String) -> String:
	var candidate := requested_name
	var suffix := 2
	while parent.get_node_or_null(NodePath(candidate)) != null:
		candidate = "%s%d" % [requested_name, suffix]
		suffix += 1
	return candidate

extends StaticBody3D

signal activated(action_id: String, display_name: String)

@export var action_id := ""
@export var display_name := ""
@export var interaction_hint := "Use"
@export var room_name := ""
@export var is_completed := false

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _badge: MeshInstance3D
var _badge_material: StandardMaterial3D
var _label: Label3D
var _base_y := 0.0
var _pulse_offset := 0.0


func configure(
	id: String,
	object_name: String,
	hint: String,
	room: String,
	size: Vector3,
	color: Color,
	shape_kind: String = "box"
) -> void:
	action_id = id
	display_name = object_name
	interaction_hint = hint
	room_name = room
	name = "Interactable_%s" % id
	_build_visual(size, color, shape_kind)
	_build_collision(size, shape_kind)
	_build_badge(size)


func _ready() -> void:
	# Baked interactables already contain their visual children. Recover the
	# runtime references that are normally assigned while generating them.
	if not is_instance_valid(_mesh_instance):
		_mesh_instance = get_node_or_null("Object") as MeshInstance3D
	if not is_instance_valid(_badge):
		_badge = get_node_or_null("InteractionBadge") as MeshInstance3D
	if not is_instance_valid(_label):
		_label = get_node_or_null("ObjectLabel") as Label3D
	if is_instance_valid(_mesh_instance):
		_material = _mesh_instance.material_override as StandardMaterial3D
	if is_instance_valid(_badge):
		_badge_material = _badge.material_override as StandardMaterial3D
	collision_layer = 5
	collision_mask = 0
	_pulse_offset = float(action_id.hash() % 100) * 0.07
	_base_y = _badge.position.y if is_instance_valid(_badge) else 0.0
	if is_completed:
		set_completed(true)


func _process(_delta: float) -> void:
	if is_completed or not is_instance_valid(_badge):
		return
	var clock := Time.get_ticks_msec() * 0.0018 + _pulse_offset
	_badge.position.y = _base_y + sin(clock) * 0.055
	var energy := 1.8 + sin(clock * 1.3) * 0.35
	_badge_material.emission_energy_multiplier = energy


func interact() -> void:
	if not is_completed:
		activated.emit(action_id, display_name)


func get_interaction_text() -> String:
	if is_completed:
		return ""
	return "[E]  %s  ·  %s" % [interaction_hint, display_name]


func set_completed(value: bool) -> void:
	is_completed = value
	if not is_inside_tree():
		return
	if value:
		collision_layer = 1
		if is_instance_valid(_badge):
			_badge.visible = false
		if is_instance_valid(_label):
			_label.visible = false
		if is_instance_valid(_material):
			_material.albedo_color = _material.albedo_color.darkened(0.32)
	else:
		collision_layer = 5
		if is_instance_valid(_badge):
			_badge.visible = true
		if is_instance_valid(_label):
			_label.visible = true


func _build_visual(size: Vector3, color: Color, shape_kind: String) -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Object"
	var mesh: PrimitiveMesh
	if shape_kind == "cylinder":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = size.x * 0.5
		cylinder.bottom_radius = size.x * 0.5
		cylinder.height = size.y
		cylinder.radial_segments = 20
		mesh = cylinder
	elif shape_kind == "sphere":
		var sphere := SphereMesh.new()
		sphere.radius = size.x * 0.5
		sphere.height = size.y
		sphere.radial_segments = 18
		sphere.rings = 9
		mesh = sphere
	else:
		var box := BoxMesh.new()
		box.size = size
		mesh = box
	_mesh_instance.mesh = mesh
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.metallic = 0.22
	_material.roughness = 0.42
	_mesh_instance.material_override = _material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mesh_instance)


func _build_collision(size: Vector3, shape_kind: String) -> void:
	var collision := CollisionShape3D.new()
	var shape: Shape3D
	if shape_kind == "cylinder":
		var cylinder := CylinderShape3D.new()
		cylinder.radius = size.x * 0.5
		cylinder.height = size.y
		shape = cylinder
	elif shape_kind == "sphere":
		var sphere := SphereShape3D.new()
		sphere.radius = maxf(size.x, size.y) * 0.5
		shape = sphere
	else:
		var box := BoxShape3D.new()
		box.size = size
		shape = box
	collision.shape = shape
	add_child(collision)


func _build_badge(size: Vector3) -> void:
	_badge = MeshInstance3D.new()
	_badge.name = "InteractionBadge"
	var badge_mesh := SphereMesh.new()
	badge_mesh.radius = 0.075
	badge_mesh.height = 0.15
	badge_mesh.radial_segments = 12
	badge_mesh.rings = 6
	_badge.mesh = badge_mesh
	_badge.position = Vector3(0.0, size.y * 0.5 + 0.24, 0.0)
	_badge_material = StandardMaterial3D.new()
	_badge_material.albedo_color = Color("ffcf66")
	_badge_material.emission_enabled = true
	_badge_material.emission = Color("ffb938")
	_badge_material.emission_energy_multiplier = 2.0
	_badge.material_override = _badge_material
	add_child(_badge)

	_label = Label3D.new()
	_label.name = "ObjectLabel"
	_label.text = display_name.to_upper()
	_label.position = Vector3(0.0, size.y * 0.5 + 0.46, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = false
	_label.font_size = 22
	_label.outline_size = 8
	_label.modulate = Color("ffe7ae")
	_label.outline_modulate = Color("171119dc")
	add_child(_label)

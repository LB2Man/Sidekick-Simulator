extends Node3D

signal action_requested(action_id: String, object_name: String)

var action_nodes: Dictionary = {}
var room_centers := {
	"LOBBY": Vector2(0.0, -2.0),
	"KITCHEN": Vector2(-17.0, -2.0),
	"BATHROOM": Vector2(17.0, -2.0),
	"WORKSHOP": Vector2(17.0, 16.0),
	"GARAGE": Vector2(0.0, 18.0),
	"PRISON WING": Vector2(-17.0, 16.0),
}


func _ready() -> void:
	action_nodes.clear()
	_index_interactables(self)
	if action_nodes.is_empty():
		push_error("Editable mansion scene does not contain any interactables.")


func set_action_completed(action_id: String, completed: bool = true) -> void:
	if action_nodes.has(action_id):
		action_nodes[action_id].set_completed(completed)


func set_bath_water_level(level: float) -> void:
	var water := get_node_or_null("BathStation/Props/BathWater") as Node3D
	if not is_instance_valid(water):
		return
	var amount := clampf(level, 0.0, 1.0)
	water.visible = amount > 0.01
	water.position.y = 0.10 + amount * 0.27
	water.scale.y = maxf(0.15, amount * 4.0)


func set_bath_towel_state(state: String) -> void:
	var towel := get_node_or_null("BathStation/Props/TowelOnWarmer") as Node3D
	if is_instance_valid(towel):
		towel.visible = state in ["warming", "ready"]
	set_bath_towel_heat(1.0 if state == "ready" else 0.0)


func set_bath_towel_heat(progress: float) -> void:
	var mesh := get_node_or_null("BathStation/Props/TowelOnWarmer/Mesh") as MeshInstance3D
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
	var soap := get_node_or_null("BathStation/Props/ShowerSoapCube") as Node3D
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


func _index_interactables(parent: Node) -> void:
	for item in parent.get_children():
		if item.has_method("get_interaction_text") and not str(item.action_id).is_empty():
			action_nodes[str(item.action_id)] = item
			if item.has_signal("activated") and not item.activated.is_connected(_on_interactable_activated):
				item.activated.connect(_on_interactable_activated)
		_index_interactables(item)


func _on_interactable_activated(action_id: String, object_name: String) -> void:
	action_requested.emit(action_id, object_name)

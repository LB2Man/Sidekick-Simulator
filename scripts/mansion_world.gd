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


func get_action_position(action_id: String) -> Vector3:
	if action_nodes.has(action_id):
		return action_nodes[action_id].global_position
	return Vector3.ZERO


func get_room_for_position(position: Vector3) -> String:
	if position.z < 7.0:
		if position.x < -8.0:
			return "KITCHEN"
		if position.x > 8.0:
			return "BATHROOM"
		return "LOBBY"
	if position.x < -8.0:
		return "PRISON WING"
	if position.x > 8.0:
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

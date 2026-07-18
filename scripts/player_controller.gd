extends CharacterBody3D

signal focus_changed(prompt: String)
signal interaction_requested(target: Node)
signal tool_selected(index: int)

const WALK_SPEED := 4.6
const SPRINT_SPEED := 7.5
const CROUCH_SPEED := 2.5
const GROUND_ACCELERATION := 18.0
const AIR_ACCELERATION := 5.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 17.0
const MAX_STEP_HEIGHT := 0.45
const STEP_FLOOR_MARGIN := 0.04
const STEP_CAMERA_RECOVERY_SPEED := 2.8
const STAND_HEIGHT := 1.78
const CROUCH_HEIGHT := 1.18
const STAND_HEAD_Y := 1.62
const CROUCH_HEAD_Y := 1.05

var mouse_sensitivity := 0.0022
var reduced_motion := false
var spawn_point := Vector3(0.0, 0.08, 1.5)

var _head: Node3D
var _camera: Camera3D
var _ray: RayCast3D
var _collision: CollisionShape3D
var _capsule: CapsuleShape3D
var _focused: Node
var _pitch := 0.0
var _bob_time := 0.0
var _camera_base_position := Vector3.ZERO
var _is_crouched := false
var _step_camera_offset := 0.0


func _ready() -> void:
	add_to_group("player")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = MAX_STEP_HEIGHT + STEP_FLOOR_MARGIN
	floor_max_angle = deg_to_rad(48.0)
	_register_input_actions()
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_update_crouch(delta)
	var was_grounded := is_on_floor()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump") and not _is_crouched:
		velocity.y = JUMP_VELOCITY

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (_head.global_basis.x * input_vector.x + _head.global_basis.z * input_vector.y)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var speed := CROUCH_SPEED if _is_crouched else (SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	var target := direction * speed
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	var movement_start := global_transform
	var horizontal_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	move_and_slide()
	if was_grounded and velocity.y <= 0.0:
		_try_step_up(movement_start, horizontal_motion)
	_update_camera_motion(delta, direction.length_squared() > 0.02)
	_update_focus()

	if global_position.y < -8.0:
		respawn()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.48, 1.38)
		_camera.rotation.x = _pitch
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and is_instance_valid(_focused):
			interaction_requested.emit(_focused)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
			tool_selected.emit(int(event.physical_keycode - KEY_1))


func set_spawn_point(value: Vector3) -> void:
	spawn_point = value


func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	_step_camera_offset = 0.0


func get_camera() -> Camera3D:
	return _camera


func set_look_sensitivity(value: float) -> void:
	mouse_sensitivity = value


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value and is_instance_valid(_camera):
		_step_camera_offset = 0.0
		_camera.position = _camera_base_position
		_camera.fov = 72.0


func _build_body() -> void:
	_collision = CollisionShape3D.new()
	_collision.name = "PlayerCollision"
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.36
	_capsule.height = STAND_HEIGHT
	_collision.shape = _capsule
	_collision.position.y = STAND_HEIGHT * 0.5
	add_child(_collision)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position.y = STAND_HEAD_Y
	add_child(_head)

	_camera = Camera3D.new()
	_camera.name = "FirstPersonCamera"
	_camera.current = true
	_camera.fov = 72.0
	_camera.near = 0.045
	_head.add_child(_camera)
	_camera_base_position = _camera.position

	_ray = RayCast3D.new()
	_ray.name = "InteractionRay"
	_ray.target_position = Vector3(0.0, 0.0, -3.35)
	_ray.collision_mask = 4
	_ray.collide_with_areas = true
	_ray.collide_with_bodies = true
	_camera.add_child(_ray)

	var hand_light := SpotLight3D.new()
	hand_light.name = "ButlerLamp"
	hand_light.light_color = Color("dcecff")
	hand_light.light_energy = 0.38
	hand_light.spot_range = 7.0
	hand_light.spot_angle = 42.0
	hand_light.shadow_enabled = false
	_camera.add_child(hand_light)


func _update_crouch(delta: float) -> void:
	_is_crouched = Input.is_action_pressed("crouch")
	var target_height := CROUCH_HEIGHT if _is_crouched else STAND_HEIGHT
	var target_head := CROUCH_HEAD_Y if _is_crouched else STAND_HEAD_Y
	_capsule.height = move_toward(_capsule.height, target_height, delta * 4.5)
	_collision.position.y = _capsule.height * 0.5
	_head.position.y = move_toward(_head.position.y, target_head, delta * 4.5)


func _update_camera_motion(delta: float, moving: bool) -> void:
	if reduced_motion:
		return
	_step_camera_offset = move_toward(
		_step_camera_offset,
		0.0,
		STEP_CAMERA_RECOVERY_SPEED * delta
	)
	var target_position := _camera_base_position
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if moving and is_on_floor():
		_bob_time += delta * horizontal_speed * 1.7
		target_position.x += sin(_bob_time) * 0.018
		target_position.y += abs(cos(_bob_time * 0.5)) * 0.022
		target_position.y += _step_camera_offset
		_camera.position = target_position
	else:
		target_position.y += _step_camera_offset
		_camera.position = _camera.position.lerp(target_position, delta * 8.0)
	var target_fov := 76.0 if Input.is_action_pressed("sprint") and not _is_crouched else 72.0
	_camera.fov = lerpf(_camera.fov, target_fov, delta * 6.0)


func _try_step_up(start: Transform3D, horizontal_motion: Vector3) -> bool:
	if horizontal_motion.length_squared() <= 0.000001:
		return false
	if not _body_test_motion(start, horizontal_motion):
		return false

	var upward_motion := Vector3.UP * MAX_STEP_HEIGHT
	if _body_test_motion(start, upward_motion):
		return false

	var raised_start := start.translated(upward_motion)
	if _body_test_motion(raised_start, horizontal_motion):
		return false

	var raised_forward := raised_start.translated(horizontal_motion)
	var downward_motion := Vector3.DOWN * (MAX_STEP_HEIGHT + STEP_FLOOR_MARGIN)
	var floor_result := PhysicsTestMotionResult3D.new()
	if not _body_test_motion(raised_forward, downward_motion, floor_result):
		return false
	if floor_result.get_collision_normal().y < cos(floor_max_angle):
		return false

	var landing_transform := raised_forward.translated(floor_result.get_travel())
	var step_height := landing_transform.origin.y - start.origin.y
	if step_height <= 0.01 or step_height > MAX_STEP_HEIGHT + 0.001:
		return false

	global_transform = landing_transform
	if not reduced_motion:
		_step_camera_offset -= step_height
	return true


func _body_test_motion(
	from: Transform3D,
	motion: Vector3,
	result: PhysicsTestMotionResult3D = null
) -> bool:
	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = from
	parameters.motion = motion
	return PhysicsServer3D.body_test_motion(get_rid(), parameters, result)


func _update_focus() -> void:
	var target: Node = null
	if _ray.is_colliding():
		target = _ray.get_collider()
	if target == _focused:
		return
	_focused = target
	if is_instance_valid(_focused) and _focused.has_method("get_interaction_text"):
		focus_changed.emit(_focused.get_interaction_text())
	else:
		focus_changed.emit("")


func _register_input_actions() -> void:
	_add_action_key("move_forward", KEY_W)
	_add_action_key("move_back", KEY_S)
	_add_action_key("move_left", KEY_A)
	_add_action_key("move_right", KEY_D)
	_add_action_key("jump", KEY_SPACE)
	_add_action_key("sprint", KEY_SHIFT)
	_add_action_key("crouch", KEY_CTRL)


func _add_action_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

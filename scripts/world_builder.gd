extends Node3D

signal action_requested(action_id: String, object_name: String)

const Interactable = preload("res://scripts/interactable.gd")

const C_WOOD := Color("3b241f")
const C_WOOD_LIGHT := Color("6d4730")
const C_STONE := Color("27313d")
const C_WALL := Color("34303b")
const C_WALL_WARM := Color("514449")
const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_TEAL := Color("178b8f")
const C_RED := Color("a94444")
const C_CREAM := Color("d6c8ad")
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
	_architecture = _folder("Architecture")
	_props = _folder("Props")
	_interactables = _folder("Interactables")
	_lights = _folder("Lighting")
	_build_environment()
	_build_shell()
	_build_lobby()
	_build_kitchen()
	_build_bathroom()
	_build_workshop()
	_build_garage()
	_build_prison()


func _index_baked_world() -> void:
	_architecture = get_node_or_null("Architecture") as Node3D
	_props = get_node_or_null("Props") as Node3D
	_interactables = get_node_or_null("Interactables") as Node3D
	_lights = get_node_or_null("Lighting") as Node3D
	action_nodes.clear()
	if not is_instance_valid(_interactables):
		push_error("Baked mansion scene is missing its Interactables folder.")
		return
	for item in _interactables.get_children():
		if item.has_method("get_interaction_text") and not str(item.action_id).is_empty():
			action_nodes[str(item.action_id)] = item
			if item.has_signal("activated") and not item.activated.is_connected(_on_interactable_activated):
				item.activated.connect(_on_interactable_activated)


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


func _build_lobby() -> void:
	_room_title("THE GRAND FOYER", Vector3(0.0, 3.25, -10.68), Vector3(0.0, 0.0, 0.0), C_GOLD)
	_block(_props, "FoyerRug", Vector3(0.0, 0.08, -1.8), Vector3(5.4, 0.08, 8.8), Color("6f2630"), false)
	for x in [-3.2, 3.2]:
		_cylinder(_props, "MarbleColumn", Vector3(x, 1.8, -6.3), 0.34, 3.6, Color("b9ae9b"), true)
		_cylinder(_props, "ColumnBase", Vector3(x, 0.18, -6.3), 0.52, 0.22, C_GOLD)

	# Butler's central desk and illuminated task board.
	_block(_props, "ButlerDesk", Vector3(-3.6, 0.62, 3.5), Vector3(2.6, 1.15, 1.1), C_WOOD_LIGHT)
	var board := _make_interactable("task_board", "Daily Task Board", "Review", "LOBBY", Vector3(2.6, 1.55, 0.18), Color("18323b"), Vector3(-3.6, 2.25, 4.05))
	board.rotation_degrees.y = 180.0
	_add_light(Vector3(-3.6, 3.3, 3.4), C_CYAN, 1.7, 4.8)

	# Fireplace and portrait wall: cozy counterpoint to the lair.
	_block(_props, "Fireplace", Vector3(5.55, 1.0, -4.0), Vector3(1.1, 2.0, 3.6), Color("4d3b3b"))
	_block(_props, "Firebox", Vector3(4.95, 0.68, -4.0), Vector3(0.16, 0.9, 1.7), C_INK, false)
	for i in range(5):
		_sphere(_props, "FireGlow", Vector3(4.82, 0.45 + (i % 2) * 0.18, -4.55 + i * 0.28), 0.17, Color("ff8c35"), true, 2.4)
	_add_light(Vector3(4.25, 1.05, -4.0), Color("ff9c55"), 2.7, 6.0)
	_block(_props, "Portrait", Vector3(5.75, 2.75, 1.4), Vector3(0.12, 2.05, 2.7), Color("171f2b"), false)
	_block(_props, "PortraitFrame", Vector3(5.67, 2.75, 1.4), Vector3(0.05, 2.35, 3.0), C_GOLD, false, 0.45)
	_raccoon_emblem(Vector3(5.60, 2.82, 1.4), Vector3(0.0, 0.0, 90.0), 0.75)

	# Mansion chandelier.
	_cylinder(_props, "ChandelierStem", Vector3(0.0, 4.15, -2.0), 0.05, 1.0, C_GOLD)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var bulb_pos := Vector3(cos(angle) * 1.0, 3.65, -2.0 + sin(angle) * 1.0)
		_sphere(_props, "ChandelierBulb", bulb_pos, 0.10, Color("ffd9a0"), true, 1.8)
	_add_light(Vector3(0.0, 3.65, -2.0), Color("ffd3a0"), 2.0, 10.5)


func _build_kitchen() -> void:
	_room_title("KITCHEN & SERVICE", Vector3(-17.5, 3.28, -10.68), Vector3.ZERO, C_CREAM)
	# Continuous cabinetry gives the room a convincing working-kitchen silhouette.
	_block(_props, "BackCounter", Vector3(-17.5, 0.55, -9.8), Vector3(17.0, 1.05, 1.5), C_WOOD_LIGHT)
	_block(_props, "WestCounter", Vector3(-25.5, 0.55, -2.0), Vector3(1.45, 1.05, 13.5), C_WOOD_LIGHT)
	_block(_props, "KitchenIsland", Vector3(-17.2, 0.72, -1.8), Vector3(5.8, 1.4, 2.5), Color("314048"))
	_block(_props, "IslandTop", Vector3(-17.2, 1.47, -1.8), Vector3(6.1, 0.12, 2.8), C_CREAM)
	for x in [-23.5, -20.7, -17.9, -15.1, -12.3, -9.5]:
		_block(_props, "CabinetDoor", Vector3(x, 2.3, -10.25), Vector3(2.25, 1.1, 0.18), Color("594030"), false)

	_make_interactable("breakfast_eggs", "Moon-hen egg basket", "Take two eggs from", "KITCHEN", Vector3(0.85, 0.35, 0.7), Color("c9ab76"), Vector3(-19.1, 1.72, -1.8))
	_make_interactable("breakfast_coffee", "Espresso automaton", "Brew extra-dark at", "KITCHEN", Vector3(0.9, 1.1, 0.72), Color("26313c"), Vector3(-12.2, 1.58, -9.15))
	_make_interactable("breakfast_cook", "Copper induction range", "Cook on", "KITCHEN", Vector3(1.65, 0.25, 1.1), Color("92563f"), Vector3(-16.8, 1.68, -1.8))
	_make_interactable("breakfast_plate", "Silver service pass", "Plate breakfast at", "KITCHEN", Vector3(1.3, 0.18, 0.9), Color("bac4c9"), Vector3(-14.4, 1.64, -1.8))
	for i in range(3):
		_cylinder(_props, "CopperPan", Vector3(-22.3 + i * 0.62, 2.65, -10.55), 0.24, 0.12, Color("b06d4d"))
	_add_light(Vector3(-17.0, 3.85, -2.0), Color("ffe4bd"), 2.25, 11.0)
	_add_light(Vector3(-23.0, 3.4, -8.5), Color("ffd0a0"), 1.1, 6.0)


func _build_bathroom() -> void:
	_room_title("HERO BATH & RECOVERY", Vector3(17.5, 3.28, -10.68), Vector3.ZERO, Color("a9e9e2"))
	# Raised tiled bath platform.
	_block(_props, "BathDais", Vector3(18.3, 0.18, -2.3), Vector3(10.2, 0.35, 7.2), Color("647c82"))
	_block(_props, "TubLeft", Vector3(15.2, 0.82, -2.3), Vector3(0.55, 1.3, 5.3), C_CREAM)
	_block(_props, "TubRight", Vector3(21.4, 0.82, -2.3), Vector3(0.55, 1.3, 5.3), C_CREAM)
	_block(_props, "TubFront", Vector3(18.3, 0.82, 0.1), Vector3(6.7, 1.3, 0.55), C_CREAM)
	_block(_props, "TubBack", Vector3(18.3, 0.82, -4.7), Vector3(6.7, 1.3, 0.55), C_CREAM)
	_block(_props, "BathWater", Vector3(18.3, 0.48, -2.3), Vector3(5.65, 0.08, 4.3), Color("439ab2a8"), false, 0.5)
	_make_interactable("bath_temperature", "Warm brass mixer", "Set 39°C on", "BATHROOM", Vector3(0.48, 0.48, 0.48), C_GOLD, Vector3(21.1, 1.72, -4.3), "sphere")
	_make_interactable("bath_products", "Cedar bath salts", "Add", "BATHROOM", Vector3(0.55, 0.8, 0.55), Color("7d4f35"), Vector3(22.7, 0.72, -5.3), "cylinder")
	_make_interactable("bath_fill", "Faucet lever", "Fill tub with", "BATHROOM", Vector3(0.35, 0.72, 0.35), C_CYAN, Vector3(20.3, 1.75, -4.4), "cylinder")
	_make_interactable("bath_stop", "Emergency stop valve", "Stop water at", "BATHROOM", Vector3(0.55, 0.55, 0.25), C_RED, Vector3(18.3, 1.58, -4.58))
	_block(_props, "TowelCabinet", Vector3(25.25, 1.15, 1.8), Vector3(1.3, 2.3, 4.0), Color("42545b"))
	for y in [0.65, 1.25, 1.85]:
		_block(_props, "FoldedTowel", Vector3(24.55, y, 1.8), Vector3(0.12, 0.28, 2.4), Color("d7e5df"), false)
	_add_light(Vector3(18.0, 3.75, -2.0), Color("b8f4ec"), 2.25, 10.0)
	_add_light(Vector3(24.5, 3.1, -8.0), Color("7adce6"), 0.95, 5.0)


func _build_workshop() -> void:
	_room_title("GADGET LAB & SUIT CARE", Vector3(17.5, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), C_CYAN)
	_block(_props, "GadgetBench", Vector3(20.6, 0.75, 20.0), Vector3(10.0, 1.45, 2.2), Color("263c46"))
	_block(_props, "BenchGlow", Vector3(20.6, 1.5, 19.25), Vector3(9.6, 0.06, 0.12), C_CYAN, false, 2.2)
	for x in [10.3, 13.5, 16.7, 19.9, 23.1]:
		_block(_props, "Monitor", Vector3(x, 2.55, 27.5), Vector3(2.45, 1.25, 0.18), Color("123d4b"), false, 1.2)
		_block(_props, "MonitorLine", Vector3(x, 2.55, 27.38), Vector3(1.55, 0.08, 0.04), C_CYAN, false, 2.3)

	_make_interactable("gadget_open", "Grapnel casing", "Open", "WORKSHOP", Vector3(1.2, 0.34, 0.68), Color("4b6570"), Vector3(17.7, 1.63, 19.8))
	_make_interactable("gadget_wires", "Wire matrix", "Reconnect", "WORKSHOP", Vector3(1.15, 0.5, 0.18), Color("693b59"), Vector3(19.4, 1.82, 19.02))
	_make_interactable("gadget_battery", "Charged power cell", "Install", "WORKSHOP", Vector3(0.42, 0.82, 0.42), C_CYAN, Vector3(21.2, 1.95, 19.8), "cylinder")
	_make_interactable("gadget_calibrate", "Calibration dial", "Tune", "WORKSHOP", Vector3(0.62, 0.62, 0.28), C_GOLD, Vector3(22.9, 1.82, 19.05), "cylinder")
	_make_interactable("gadget_close", "Return cradle", "Seal gadget in", "WORKSHOP", Vector3(1.3, 0.32, 0.85), Color("2b5660"), Vector3(24.8, 1.64, 19.8))

	# Suit-care line along the east wall.
	for z in [9.6, 12.7, 15.8, 18.9, 22.0, 25.1]:
		_block(_props, "SuitBay", Vector3(25.8, 1.65, z), Vector3(1.5, 3.1, 2.35), Color("25313c"))
	var suit_actions := [
		["suit_inspect", "Inspection scanner", "Scan suit with", "9.6", C_CYAN],
		["suit_wash", "Suit washer", "Wash suit in", "12.7", Color("48717d")],
		["suit_dry", "Ion drying chamber", "Dry suit in", "15.8", Color("526b87")],
		["suit_repair", "Ballistic repair bench", "Patch tear at", "18.9", C_GOLD],
		["suit_polish", "Emblem polishing wheel", "Polish at", "22.0", Color("b7c3cb")],
		["suit_display", "Suit display cradle", "Return suit to", "25.1", Color("324e59")],
	]
	for item in suit_actions:
		_make_interactable(item[0], item[1], item[2], "WORKSHOP", Vector3(0.55, 1.25, 1.25), item[4], Vector3(24.95, 1.7, float(item[3])))
	# A graphic raccoon suit silhouette in the final display.
	_sphere(_props, "SuitHead", Vector3(25.35, 2.55, 25.1), 0.28, C_INK)
	_block(_props, "SuitBody", Vector3(25.38, 1.72, 25.1), Vector3(0.34, 1.25, 0.75), Color("293b49"), false)
	_add_light(Vector3(18.0, 3.65, 18.0), C_CYAN, 2.2, 12.0)
	_add_light(Vector3(25.0, 3.2, 24.0), Color("f6c879"), 1.4, 6.0)


func _build_garage() -> void:
	_room_title("RACCOON ROADSTER BAY", Vector3(0.0, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), C_CYAN)
	# Hero car: a broad stylized silhouette with teal tech light and gold trim.
	_block(_props, "RoadsterBody", Vector3(0.0, 0.83, 18.0), Vector3(4.8, 0.85, 8.6), Color("172735"))
	_block(_props, "RoadsterCab", Vector3(0.0, 1.55, 17.3), Vector3(3.6, 0.85, 3.6), Color("213e4c"))
	_block(_props, "Windshield", Vector3(0.0, 1.74, 15.48), Vector3(3.2, 0.45, 0.08), Color("4db8c1"), false, 1.0)
	_block(_props, "RoadsterStripe", Vector3(0.0, 1.28, 20.4), Vector3(0.42, 0.06, 3.4), C_GOLD, false, 1.2)
	for x in [-2.25, 2.25]:
		for z in [15.7, 20.2]:
			_cylinder(_props, "RoadsterWheel", Vector3(x, 0.65, z), 0.72, 0.48, C_INK, true, 0.0, Vector3(0.0, 0.0, 90.0))
			_cylinder(_props, "WheelHub", Vector3(x * 1.01, 0.65, z), 0.3, 0.52, C_GOLD, false, 0.8, Vector3(0.0, 0.0, 90.0))
	# Mask-like headlights.
	for x in [-1.35, 1.35]:
		_sphere(_props, "Headlight", Vector3(x, 1.0, 13.66), 0.23, C_CYAN, true, 2.8)
	_add_light(Vector3(0.0, 1.0, 12.9), C_CYAN, 1.0, 7.0)

	_make_interactable("car_refuel", "Stealth-fuel pump", "Refuel from", "GARAGE", Vector3(1.0, 2.1, 0.9), Color("45525b"), Vector3(-5.8, 1.05, 20.7))
	_make_interactable("car_tires", "Tire console", "Set tire pressure at", "GARAGE", Vector3(1.25, 1.1, 0.55), Color("315e68"), Vector3(5.9, 0.78, 16.0))
	_make_interactable("car_clean", "Roadster wash controls", "Clean car using", "GARAGE", Vector3(1.25, 1.1, 0.55), Color("2a7983"), Vector3(5.9, 0.78, 20.0))
	_make_interactable("car_load", "Smoke-acorn trunk", "Load gadgets into", "GARAGE", Vector3(2.0, 0.34, 1.2), C_GOLD, Vector3(0.0, 1.42, 21.5))
	# Ceiling service stripes and hazard floor lines.
	for x in [-6.8, 6.8]:
		_block(_props, "HazardLine", Vector3(x, 0.09, 18.0), Vector3(0.16, 0.08, 16.0), C_GOLD, false, 1.0)
	for z in [9.0, 26.0]:
		_block(_props, "HazardLine", Vector3(0.0, 0.09, z), Vector3(13.6, 0.08, 0.16), C_GOLD, false, 1.0)
	_add_light(Vector3(0.0, 3.75, 18.0), Color("79dce8"), 2.3, 12.5)
	_add_light(Vector3(0.0, 3.75, 25.0), Color("78b9d8"), 1.5, 8.0)


func _build_prison() -> void:
	_room_title("SECURE HOLDING · CELL 01", Vector3(-17.5, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), Color("e5a86e"))
	# Cell occupies the rear half, with readable bars and a safe service aisle.
	_block(_props, "CellBack", Vector3(-17.5, 2.1, 26.9), Vector3(16.5, 4.1, 0.55), Color("24272b"))
	for x in [-25.0, -24.0, -23.0, -22.0, -21.0, -20.0, -19.0, -18.0, -17.0, -16.0, -15.0, -14.0, -13.0, -12.0, -11.0, -10.0]:
		_cylinder(_props, "CellBar", Vector3(x, 2.2, 18.2), 0.075, 4.2, Color("626c73"), true, 0.0)
	_block(_props, "BarTop", Vector3(-17.5, 4.18, 18.2), Vector3(16.5, 0.18, 0.24), Color("626c73"))
	_block(_props, "BarBottom", Vector3(-17.5, 0.2, 18.2), Vector3(16.5, 0.18, 0.24), Color("626c73"))
	# Comedic villain presence behind the bars.
	_sphere(_props, "VillainHead", Vector3(-18.5, 1.9, 23.0), 0.42, Color("75506f"))
	_block(_props, "VillainBody", Vector3(-18.5, 0.95, 23.0), Vector3(0.85, 1.4, 0.62), Color("4d334f"), false)
	for x in [-18.68, -18.32]:
		_sphere(_props, "VillainEye", Vector3(x, 2.0, 22.62), 0.06, Color("f0d46a"), true, 1.5)
	var quote := Label3D.new()
	quote.text = "‘Your soup lacks menace.’"
	quote.position = Vector3(-18.5, 2.8, 22.5)
	quote.font_size = 24
	quote.outline_size = 8
	quote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_props.add_child(quote)

	_make_interactable("cell_unlock", "Secure hatch lock", "Unlock", "PRISON WING", Vector3(0.55, 0.72, 0.25), C_RED, Vector3(-23.5, 1.25, 18.0))
	_make_interactable("cell_food", "Approved villain lunch", "Deliver", "PRISON WING", Vector3(1.05, 0.5, 0.8), Color("a97a4d"), Vector3(-21.5, 0.45, 14.6))
	_make_interactable("cell_clean", "Cell sanitation console", "Sanitize floor from", "PRISON WING", Vector3(1.1, 1.15, 0.55), Color("2e7279"), Vector3(-13.2, 0.68, 14.4))
	_make_interactable("cell_lock", "Security verification panel", "Lock and verify", "PRISON WING", Vector3(0.8, 1.2, 0.28), C_GOLD, Vector3(-11.3, 1.2, 18.0))
	_block(_props, "SecurityDesk", Vector3(-17.0, 0.65, 10.2), Vector3(4.4, 1.2, 1.3), Color("303a41"))
	for i in range(3):
		_block(_props, "SecurityScreen", Vector3(-18.3 + i * 1.3, 1.55, 10.25), Vector3(1.0, 0.62, 0.12), Color("3b2229") if i == 1 else Color("183f48"), false, 1.2)
	_add_light(Vector3(-17.5, 3.55, 13.0), Color("d9d7c9"), 1.25, 8.0)
	_add_light(Vector3(-18.0, 3.2, 23.0), Color("dc6c5d"), 1.3, 7.0)


func _make_interactable(
	action_id: String,
	object_name: String,
	hint: String,
	room: String,
	size: Vector3,
	color: Color,
	position: Vector3,
	shape_kind: String = "box"
) -> Node:
	var item := Interactable.new()
	item.configure(action_id, object_name, hint, room, size, color, shape_kind)
	item.position = position
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
	position: Vector3,
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
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		static_body.add_child(collision)
		body = static_body
	else:
		body = Node3D.new()
	body.name = object_name
	body.position = position
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
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
	position: Vector3,
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
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		static_body.add_child(collision)
		body = static_body
	else:
		body = Node3D.new()
	body.name = object_name
	body.position = position
	body.rotation_degrees = rotation_degrees_value
	parent.add_child(body)
	var instance := MeshInstance3D.new()
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
	position: Vector3,
	radius: float,
	color: Color,
	emissive: bool = false,
	emission_energy: float = 0.0
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name
	instance.position = position
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


func _add_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.omni_attenuation = 1.1
	light.shadow_enabled = true
	_lights.add_child(light)


func _room_title(text: String, position: Vector3, rotation_value: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.rotation_degrees = rotation_value
	label.font_size = 34
	label.outline_size = 10
	label.modulate = color
	label.outline_modulate = Color("090b11e8")
	label.no_depth_test = false
	_props.add_child(label)


func _raccoon_emblem(position: Vector3, rotation_value: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.name = "RaccoonEmblem"
	root.position = position
	root.rotation_degrees = rotation_value
	root.scale = Vector3.ONE * scale_value
	_props.add_child(root)
	_sphere(root, "Mask", Vector3.ZERO, 0.72, Color("51616c"))
	for x in [-0.36, 0.36]:
		_sphere(root, "EyePatch", Vector3(x, 0.08, -0.58), 0.22, C_INK)
		_sphere(root, "EyeGlow", Vector3(x, 0.08, -0.76), 0.065, C_CYAN, true, 2.0)
	_sphere(root, "Nose", Vector3(0.0, -0.28, -0.68), 0.12, C_INK)

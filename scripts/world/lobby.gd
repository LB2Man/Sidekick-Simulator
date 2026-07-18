extends RefCounted

const C_WOOD_LIGHT := Color("6d4730")
const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_INK := Color("11151d")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("THE GRAND FOYER", Vector3(0.0, 3.25, -10.68), Vector3.ZERO, C_GOLD)
	world.add_block(props, "FoyerRug", Vector3(0.0, 0.08, -1.8), Vector3(5.4, 0.08, 8.8), Color("6f2630"), false)
	for x in [-3.2, 3.2]:
		world.add_cylinder(props, "MarbleColumn", Vector3(x, 1.8, -6.3), 0.34, 3.6, Color("b9ae9b"), true)
		world.add_cylinder(props, "ColumnBase", Vector3(x, 0.18, -6.3), 0.52, 0.22, C_GOLD)

	world.add_block(props, "ButlerDesk", Vector3(-3.6, 0.62, 3.5), Vector3(2.6, 1.15, 1.1), C_WOOD_LIGHT)
	var board = world.add_interactable(
		"task_board", "Daily Task Board", "Review", "LOBBY",
		Vector3(2.6, 1.55, 0.18), Color("18323b"), Vector3(-3.6, 2.25, 4.05)
	)
	board.rotation_degrees.y = 180.0
	world.add_room_light(Vector3(-3.6, 3.3, 3.4), C_CYAN, 1.7, 4.8)

	world.add_block(props, "Fireplace", Vector3(5.55, 1.0, -4.0), Vector3(1.1, 2.0, 3.6), Color("4d3b3b"))
	world.add_block(props, "Firebox", Vector3(4.95, 0.68, -4.0), Vector3(0.16, 0.9, 1.7), C_INK, false)
	for i in range(5):
		world.add_sphere(props, "FireGlow", Vector3(4.82, 0.45 + (i % 2) * 0.18, -4.55 + i * 0.28), 0.17, Color("ff8c35"), true, 2.4)
	world.add_room_light(Vector3(4.25, 1.05, -4.0), Color("ff9c55"), 2.7, 6.0)
	world.add_block(props, "Portrait", Vector3(5.75, 2.75, 1.4), Vector3(0.12, 2.05, 2.7), Color("171f2b"), false)
	world.add_block(props, "PortraitFrame", Vector3(5.67, 2.75, 1.4), Vector3(0.05, 2.35, 3.0), C_GOLD, false, 0.45)
	world.add_raccoon_emblem(Vector3(5.60, 2.82, 1.4), Vector3(0.0, 0.0, 90.0), 0.75)

	world.add_cylinder(props, "ChandelierStem", Vector3(0.0, 4.15, -2.0), 0.05, 1.0, C_GOLD)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var bulb_pos := Vector3(cos(angle) * 1.0, 3.65, -2.0 + sin(angle) * 1.0)
		world.add_sphere(props, "ChandelierBulb", bulb_pos, 0.10, Color("ffd9a0"), true, 1.8)
	world.add_room_light(Vector3(0.0, 3.65, -2.0), Color("ffd3a0"), 2.0, 10.5)

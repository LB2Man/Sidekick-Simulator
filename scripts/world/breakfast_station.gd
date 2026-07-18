extends RefCounted

const C_WOOD_LIGHT := Color("6d4730")
const C_CREAM := Color("d6c8ad")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("KITCHEN & SERVICE", Vector3(-17.5, 3.28, -10.68), Vector3.ZERO, C_CREAM)
	world.add_block(props, "BackCounter", Vector3(-17.5, 0.55, -9.8), Vector3(17.0, 1.05, 1.5), C_WOOD_LIGHT)
	world.add_block(props, "WestCounter", Vector3(-25.5, 0.55, -2.0), Vector3(1.45, 1.05, 13.5), C_WOOD_LIGHT)
	world.add_block(props, "KitchenIsland", Vector3(-17.2, 0.72, -1.8), Vector3(5.8, 1.4, 2.5), Color("314048"))
	world.add_block(props, "IslandTop", Vector3(-17.2, 1.47, -1.8), Vector3(6.1, 0.12, 2.8), C_CREAM)
	for x in [-23.5, -20.7, -17.9, -15.1, -12.3, -9.5]:
		world.add_block(props, "CabinetDoor", Vector3(x, 2.3, -10.25), Vector3(2.25, 1.1, 0.18), Color("594030"), false)

	world.add_interactable("breakfast_eggs", "Moon-hen egg basket", "Take two eggs from", "KITCHEN", Vector3(0.85, 0.35, 0.7), Color("c9ab76"), Vector3(-19.1, 1.72, -1.8))
	world.add_interactable("breakfast_coffee", "Espresso automaton", "Brew extra-dark at", "KITCHEN", Vector3(0.9, 1.1, 0.72), Color("26313c"), Vector3(-12.2, 1.58, -9.15))
	world.add_interactable("breakfast_cook", "Copper induction range", "Cook on", "KITCHEN", Vector3(1.65, 0.25, 1.1), Color("92563f"), Vector3(-16.8, 1.68, -1.8))
	world.add_interactable("breakfast_plate", "Silver service pass", "Plate breakfast at", "KITCHEN", Vector3(1.3, 0.18, 0.9), Color("bac4c9"), Vector3(-14.4, 1.64, -1.8))
	for i in range(3):
		world.add_cylinder(props, "CopperPan", Vector3(-22.3 + i * 0.62, 2.65, -10.55), 0.24, 0.12, Color("b06d4d"))
	world.add_room_light(Vector3(-17.0, 3.85, -2.0), Color("ffe4bd"), 2.25, 11.0)
	world.add_room_light(Vector3(-23.0, 3.4, -8.5), Color("ffd0a0"), 1.1, 6.0)

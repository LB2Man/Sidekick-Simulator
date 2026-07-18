extends RefCounted

const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_RED := Color("a94444")
const C_CREAM := Color("d6c8ad")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("HERO BATH & RECOVERY", Vector3(17.5, 3.28, -10.68), Vector3.ZERO, Color("a9e9e2"))
	world.add_block(props, "BathDais", Vector3(18.3, 0.18, -2.3), Vector3(10.2, 0.35, 7.2), Color("647c82"))
	world.add_block(props, "TubLeft", Vector3(15.2, 0.82, -2.3), Vector3(0.55, 1.3, 5.3), C_CREAM)
	world.add_block(props, "TubRight", Vector3(21.4, 0.82, -2.3), Vector3(0.55, 1.3, 5.3), C_CREAM)
	world.add_block(props, "TubFront", Vector3(18.3, 0.82, 0.1), Vector3(6.7, 1.3, 0.55), C_CREAM)
	world.add_block(props, "TubBack", Vector3(18.3, 0.82, -4.7), Vector3(6.7, 1.3, 0.55), C_CREAM)
	world.add_block(props, "BathWater", Vector3(18.3, 0.48, -2.3), Vector3(5.65, 0.08, 4.3), Color("439ab2a8"), false, 0.5)
	world.add_interactable("bath_temperature", "Warm brass mixer", "Set 39°C on", "BATHROOM", Vector3(0.48, 0.48, 0.48), C_GOLD, Vector3(21.1, 1.72, -4.3), "sphere")
	world.add_interactable("bath_products", "Cedar bath salts", "Add", "BATHROOM", Vector3(0.55, 0.8, 0.55), Color("7d4f35"), Vector3(22.7, 0.72, -5.3), "cylinder")
	world.add_interactable("bath_fill", "Faucet lever", "Fill tub with", "BATHROOM", Vector3(0.35, 0.72, 0.35), C_CYAN, Vector3(20.3, 1.75, -4.4), "cylinder")
	world.add_interactable("bath_stop", "Emergency stop valve", "Stop water at", "BATHROOM", Vector3(0.55, 0.55, 0.25), C_RED, Vector3(18.3, 1.58, -4.58))
	world.add_block(props, "TowelCabinet", Vector3(25.25, 1.15, 1.8), Vector3(1.3, 2.3, 4.0), Color("42545b"))
	for y in [0.65, 1.25, 1.85]:
		world.add_block(props, "FoldedTowel", Vector3(24.55, y, 1.8), Vector3(0.12, 0.28, 2.4), Color("d7e5df"), false)
	world.add_room_light(Vector3(18.0, 3.75, -2.0), Color("b8f4ec"), 2.25, 10.0)
	world.add_room_light(Vector3(24.5, 3.1, -8.0), Color("7adce6"), 0.95, 5.0)

extends RefCounted

const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_RED := Color("a94444")
const C_CREAM := Color("d6c8ad")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("HERO BATH & RECOVERY", Vector3(17.5, 3.28, -10.68), Vector3.ZERO, Color("a9e9e2"))

	# The recovery bath is sunk close to floor level, with a central opening and
	# three shallow steps so the master can walk down into it.
	world.add_block(props, "BathSurround", Vector3(18.3, 0.08, -2.3), Vector3(9.4, 0.14, 6.7), Color("647c82"))
	world.add_block(props, "TubLeft", Vector3(15.2, 0.44, -2.3), Vector3(0.5, 0.78, 5.3), C_CREAM)
	world.add_block(props, "TubRight", Vector3(21.4, 0.44, -2.3), Vector3(0.5, 0.78, 5.3), C_CREAM)
	world.add_block(props, "TubBack", Vector3(18.3, 0.44, -4.7), Vector3(6.7, 0.78, 0.5), C_CREAM)
	world.add_block(props, "TubFrontLeft", Vector3(16.15, 0.44, 0.1), Vector3(2.4, 0.78, 0.5), C_CREAM)
	world.add_block(props, "TubFrontRight", Vector3(20.45, 0.44, 0.1), Vector3(2.4, 0.78, 0.5), C_CREAM)
	world.add_block(props, "BathStepTop", Vector3(18.3, 0.30, 0.55), Vector3(1.8, 0.18, 0.72), Color("9aaeb0"))
	world.add_block(props, "BathStepMiddle", Vector3(18.3, 0.20, 0.03), Vector3(1.8, 0.16, 0.55), Color("8ba0a3"))
	world.add_block(props, "BathStepBottom", Vector3(18.3, 0.11, -0.43), Vector3(1.8, 0.12, 0.5), Color("7c9296"))
	var water := world.add_block(props, "BathWater", Vector3(18.3, 0.12, -2.45), Vector3(5.65, 0.08, 3.9), Color("439ab2a8"), false, 0.5)
	water.get_parent().visible = false
	world.add_block(props, "WaterTargetLine", Vector3(15.48, 0.44, -2.45), Vector3(0.06, 0.035, 3.95), C_GOLD, false, 1.7)

	# Faucet, thermometer and the physical hot/cold mixer wheels share one wall station.
	world.add_cylinder(props, "FaucetSpout", Vector3(19.5, 0.92, -4.35), 0.10, 1.0, C_GOLD, false, 0.0, Vector3(90.0, 0.0, 0.0))
	world.add_cylinder(props, "HotMixerWheel", Vector3(20.25, 0.86, -4.38), 0.25, 0.14, C_RED, false, 0.0, Vector3(90.0, 0.0, 0.0))
	world.add_cylinder(props, "ColdMixerWheel", Vector3(21.0, 0.86, -4.38), 0.25, 0.14, C_CYAN, false, 0.0, Vector3(90.0, 0.0, 0.0))
	world.add_block(props, "ThermometerDisplay", Vector3(20.63, 1.36, -4.42), Vector3(1.35, 0.42, 0.12), Color("18323b"), false, 1.1)
	world.add_interactable("bath_temperature", "Hot and cold mixer wheels", "Balance 38°C at", "BATHROOM", Vector3(1.45, 0.56, 0.25), C_GOLD, Vector3(20.63, 1.15, -4.28))
	world.add_interactable("bath_fill", "Faucet lever", "Turn on", "BATHROOM", Vector3(0.34, 0.64, 0.34), C_CYAN, Vector3(19.45, 1.05, -4.12), "cylinder")
	world.add_interactable("bath_stop", "Faucet stop lever", "Stop water with", "BATHROOM", Vector3(0.34, 0.64, 0.34), C_RED, Vector3(18.65, 1.05, -4.12), "cylinder")

	# Wooden recovery-salt bucket.
	world.add_cylinder(props, "SaltBucketRim", Vector3(22.65, 0.58, -4.0), 0.48, 0.1, Color("b58a5a"), false)
	world.add_interactable("bath_products", "Wooden bath-salt bucket", "Add soothing salts from", "BATHROOM", Vector3(0.78, 0.72, 0.78), Color("7d4f35"), Vector3(22.65, 0.44, -4.0), "cylinder")

	# Towel storage and warmer sit together against the east wall.
	world.add_block(props, "TowelCloset", Vector3(25.55, 1.3, 1.75), Vector3(0.75, 2.5, 3.0), Color("42545b"))
	for y in [0.7, 1.3, 1.9]:
		world.add_block(props, "FoldedTowel", Vector3(25.12, y, 1.75), Vector3(0.12, 0.25, 1.9), Color("d7e5df"), false)
	world.add_interactable("bath_towel_take", "Wall towel closet", "Take a clean towel from", "BATHROOM", Vector3(0.35, 1.8, 2.3), Color("d7e5df"), Vector3(24.75, 1.3, 1.75))
	world.add_block(props, "TowelWarmer", Vector3(25.55, 1.25, -1.0), Vector3(0.65, 2.2, 2.2), Color("6b4f43"))
	for z in [-1.65, -1.22, -0.79, -0.36]:
		world.add_cylinder(props, "WarmerRail", Vector3(25.16, 1.25, z), 0.045, 1.6, C_GOLD, false, 0.3, Vector3(0.0, 0.0, 90.0))
	var warmer_towel := world.add_block(props, "TowelOnWarmer", Vector3(24.72, 1.1, -1.0), Vector3(0.08, 1.15, 1.35), Color("f1eee4"), false, 0.35)
	warmer_towel.get_parent().visible = false
	world.add_interactable("bath_towel_warm", "Towel warmer", "Place towel on", "BATHROOM", Vector3(0.32, 1.45, 1.7), Color("d7e5df"), Vector3(24.65, 1.25, -1.0))
	world.add_interactable("bath_towel_ready", "Warmer ready light", "Collect warmed towel at", "BATHROOM", Vector3(0.36, 0.36, 0.24), C_GOLD, Vector3(24.65, 0.42, -1.0), "sphere")

	# Shower and soap cabinet occupy the opposite wall.
	world.add_block(props, "ShowerBase", Vector3(10.1, 0.12, -6.2), Vector3(2.8, 0.18, 3.1), Color("a8b9b8"))
	world.add_block(props, "ShowerWall", Vector3(9.05, 1.5, -6.2), Vector3(0.18, 3.0, 3.1), Color("547179"))
	world.add_cylinder(props, "ShowerPipe", Vector3(9.45, 2.15, -6.2), 0.055, 1.25, C_GOLD, false)
	world.add_sphere(props, "ShowerHead", Vector3(9.72, 2.72, -6.2), 0.22, C_GOLD)
	world.add_block(props, "SoapCabinet", Vector3(9.45, 1.45, -8.65), Vector3(0.65, 1.8, 1.55), Color("42545b"))
	world.add_interactable("bath_soap_take", "Soap-cube cabinet", "Take one soap cube from", "BATHROOM", Vector3(0.4, 1.2, 1.15), Color("e9e0c5"), Vector3(10.0, 1.45, -8.65))
	world.add_block(props, "ShowerSoapHolder", Vector3(9.55, 1.15, -5.25), Vector3(0.5, 0.45, 0.6), Color("253846"), false)
	var shower_soap := world.add_block(props, "ShowerSoapCube", Vector3(9.9, 1.2, -5.25), Vector3(0.32, 0.28, 0.38), Color("e9e0c5"), false, 0.25)
	shower_soap.get_parent().visible = false
	world.add_interactable("bath_soap_refill", "Shower soap holder", "Refill", "BATHROOM", Vector3(0.38, 0.55, 0.65), Color("e9e0c5"), Vector3(10.05, 1.15, -5.25))
	world.add_room_light(Vector3(18.0, 3.75, -2.0), Color("b8f4ec"), 2.25, 10.0)
	world.add_room_light(Vector3(24.5, 3.1, -8.0), Color("7adce6"), 0.95, 5.0)

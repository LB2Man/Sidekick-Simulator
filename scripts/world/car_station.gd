extends RefCounted

const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_INK := Color("11151d")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("RACCOON ROADSTER BAY", Vector3(0.0, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), C_CYAN)
	world.add_block(props, "RoadsterBody", Vector3(0.0, 0.83, 18.0), Vector3(4.8, 0.85, 8.6), Color("172735"))
	world.add_block(props, "RoadsterCab", Vector3(0.0, 1.55, 17.3), Vector3(3.6, 0.85, 3.6), Color("213e4c"))
	world.add_block(props, "Windshield", Vector3(0.0, 1.74, 15.48), Vector3(3.2, 0.45, 0.08), Color("4db8c1"), false, 1.0)
	world.add_block(props, "RoadsterStripe", Vector3(0.0, 1.28, 20.4), Vector3(0.42, 0.06, 3.4), C_GOLD, false, 1.2)
	for x in [-2.25, 2.25]:
		for z in [15.7, 20.2]:
			world.add_cylinder(props, "RoadsterWheel", Vector3(x, 0.65, z), 0.72, 0.48, C_INK, true, 0.0, Vector3(0.0, 0.0, 90.0))
			world.add_cylinder(props, "WheelHub", Vector3(x * 1.01, 0.65, z), 0.3, 0.52, C_GOLD, false, 0.8, Vector3(0.0, 0.0, 90.0))
	for x in [-1.35, 1.35]:
		world.add_sphere(props, "Headlight", Vector3(x, 1.0, 13.66), 0.23, C_CYAN, true, 2.8)
	world.add_room_light(Vector3(0.0, 1.0, 12.9), C_CYAN, 1.0, 7.0)

	world.add_interactable("car_refuel", "Stealth-fuel pump", "Refuel from", "GARAGE", Vector3(1.0, 2.1, 0.9), Color("45525b"), Vector3(-5.8, 1.05, 20.7))
	world.add_interactable("car_tires", "Tire console", "Set tire pressure at", "GARAGE", Vector3(1.25, 1.1, 0.55), Color("315e68"), Vector3(5.9, 0.78, 16.0))
	world.add_interactable("car_clean", "Roadster wash controls", "Clean car using", "GARAGE", Vector3(1.25, 1.1, 0.55), Color("2a7983"), Vector3(5.9, 0.78, 20.0))
	world.add_interactable("car_load", "Smoke-acorn trunk", "Load gadgets into", "GARAGE", Vector3(2.0, 0.34, 1.2), C_GOLD, Vector3(0.0, 1.42, 21.5))
	for x in [-6.8, 6.8]:
		world.add_block(props, "HazardLine", Vector3(x, 0.09, 18.0), Vector3(0.16, 0.08, 16.0), C_GOLD, false, 1.0)
	for z in [9.0, 26.0]:
		world.add_block(props, "HazardLine", Vector3(0.0, 0.09, z), Vector3(13.6, 0.08, 0.16), C_GOLD, false, 1.0)
	world.add_room_light(Vector3(0.0, 3.75, 18.0), Color("79dce8"), 2.3, 12.5)
	world.add_room_light(Vector3(0.0, 3.75, 25.0), Color("78b9d8"), 1.5, 8.0)

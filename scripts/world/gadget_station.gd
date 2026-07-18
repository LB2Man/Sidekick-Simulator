extends RefCounted

const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("GADGET LAB & SUIT CARE", Vector3(17.5, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), C_CYAN)
	world.add_block(props, "GadgetBench", Vector3(20.6, 0.75, 20.0), Vector3(10.0, 1.45, 2.2), Color("263c46"))
	world.add_block(props, "BenchGlow", Vector3(20.6, 1.5, 19.25), Vector3(9.6, 0.06, 0.12), C_CYAN, false, 2.2)
	for x in [10.3, 13.5, 16.7, 19.9, 23.1]:
		world.add_block(props, "Monitor", Vector3(x, 2.55, 27.5), Vector3(2.45, 1.25, 0.18), Color("123d4b"), false, 1.2)
		world.add_block(props, "MonitorLine", Vector3(x, 2.55, 27.38), Vector3(1.55, 0.08, 0.04), C_CYAN, false, 2.3)

	world.add_interactable("gadget_open", "Grapnel casing", "Open", "WORKSHOP", Vector3(1.2, 0.34, 0.68), Color("4b6570"), Vector3(17.7, 1.63, 19.8))
	world.add_interactable("gadget_wires", "Wire matrix", "Reconnect", "WORKSHOP", Vector3(1.15, 0.5, 0.18), Color("693b59"), Vector3(19.4, 1.82, 19.02))
	world.add_interactable("gadget_battery", "Charged power cell", "Install", "WORKSHOP", Vector3(0.42, 0.82, 0.42), C_CYAN, Vector3(21.2, 1.95, 19.8), "cylinder")
	world.add_interactable("gadget_calibrate", "Calibration dial", "Tune", "WORKSHOP", Vector3(0.62, 0.62, 0.28), C_GOLD, Vector3(22.9, 1.82, 19.05), "cylinder")
	world.add_interactable("gadget_close", "Return cradle", "Seal gadget in", "WORKSHOP", Vector3(1.3, 0.32, 0.85), Color("2b5660"), Vector3(24.8, 1.64, 19.8))
	world.add_room_light(Vector3(18.0, 3.65, 18.0), C_CYAN, 2.2, 12.0)

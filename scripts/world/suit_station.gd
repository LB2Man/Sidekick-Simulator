extends RefCounted

const C_GOLD := Color("d7a84c")
const C_CYAN := Color("47d7e8")
const C_INK := Color("11151d")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	for z in [9.6, 12.7, 15.8, 18.9, 22.0, 25.1]:
		world.add_block(props, "SuitBay", Vector3(25.8, 1.65, z), Vector3(1.5, 3.1, 2.35), Color("25313c"))
	var suit_actions := [
		["suit_inspect", "Inspection scanner", "Scan suit with", "9.6", C_CYAN],
		["suit_wash", "Suit washer", "Wash suit in", "12.7", Color("48717d")],
		["suit_dry", "Ion drying chamber", "Dry suit in", "15.8", Color("526b87")],
		["suit_repair", "Ballistic repair bench", "Patch tear at", "18.9", C_GOLD],
		["suit_polish", "Emblem polishing wheel", "Polish at", "22.0", Color("b7c3cb")],
		["suit_display", "Suit display cradle", "Return suit to", "25.1", Color("324e59")],
	]
	for item in suit_actions:
		world.add_interactable(item[0], item[1], item[2], "WORKSHOP", Vector3(0.55, 1.25, 1.25), item[4], Vector3(24.95, 1.7, float(item[3])))
	world.add_sphere(props, "SuitHead", Vector3(25.35, 2.55, 25.1), 0.28, C_INK)
	world.add_block(props, "SuitBody", Vector3(25.38, 1.72, 25.1), Vector3(0.34, 1.25, 0.75), Color("293b49"), false)
	world.add_room_light(Vector3(25.0, 3.2, 24.0), Color("f6c879"), 1.4, 6.0)

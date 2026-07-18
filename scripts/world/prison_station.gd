extends RefCounted

const C_GOLD := Color("d7a84c")
const C_RED := Color("a94444")


static func build(world) -> void:
	var props: Node3D = world.get_props_root()
	world.add_room_title("SECURE HOLDING · CELL 01", Vector3(-17.5, 3.25, 27.68), Vector3(0.0, 180.0, 0.0), Color("e5a86e"))
	world.add_block(props, "CellBack", Vector3(-17.5, 2.1, 26.9), Vector3(16.5, 4.1, 0.55), Color("24272b"))
	for x in [-25.0, -24.0, -23.0, -22.0, -21.0, -20.0, -19.0, -18.0, -17.0, -16.0, -15.0, -14.0, -13.0, -12.0, -11.0, -10.0]:
		world.add_cylinder(props, "CellBar", Vector3(x, 2.2, 18.2), 0.075, 4.2, Color("626c73"), true, 0.0)
	world.add_block(props, "BarTop", Vector3(-17.5, 4.18, 18.2), Vector3(16.5, 0.18, 0.24), Color("626c73"))
	world.add_block(props, "BarBottom", Vector3(-17.5, 0.2, 18.2), Vector3(16.5, 0.18, 0.24), Color("626c73"))
	world.add_sphere(props, "VillainHead", Vector3(-18.5, 1.9, 23.0), 0.42, Color("75506f"))
	world.add_block(props, "VillainBody", Vector3(-18.5, 0.95, 23.0), Vector3(0.85, 1.4, 0.62), Color("4d334f"), false)
	for x in [-18.68, -18.32]:
		world.add_sphere(props, "VillainEye", Vector3(x, 2.0, 22.62), 0.06, Color("f0d46a"), true, 1.5)
	var quote := Label3D.new()
	quote.text = "‘Your soup lacks menace.’"
	quote.position = Vector3(-18.5, 2.8, 22.5)
	quote.font_size = 24
	quote.outline_size = 8
	quote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	props.add_child(quote)

	world.add_interactable("cell_unlock", "Secure hatch lock", "Unlock", "PRISON WING", Vector3(0.55, 0.72, 0.25), C_RED, Vector3(-23.5, 1.25, 18.0))
	world.add_interactable("cell_food", "Approved villain lunch", "Deliver", "PRISON WING", Vector3(1.05, 0.5, 0.8), Color("a97a4d"), Vector3(-21.5, 0.45, 14.6))
	world.add_interactable("cell_clean", "Cell sanitation console", "Sanitize floor from", "PRISON WING", Vector3(1.1, 1.15, 0.55), Color("2e7279"), Vector3(-13.2, 0.68, 14.4))
	world.add_interactable("cell_lock", "Security verification panel", "Lock and verify", "PRISON WING", Vector3(0.8, 1.2, 0.28), C_GOLD, Vector3(-11.3, 1.2, 18.0))
	world.add_block(props, "SecurityDesk", Vector3(-17.0, 0.65, 10.2), Vector3(4.4, 1.2, 1.3), Color("303a41"))
	for i in range(3):
		world.add_block(props, "SecurityScreen", Vector3(-18.3 + i * 1.3, 1.55, 10.25), Vector3(1.0, 0.62, 0.12), Color("3b2229") if i == 1 else Color("183f48"), false, 1.2)
	world.add_room_light(Vector3(-17.5, 3.55, 13.0), Color("d9d7c9"), 1.25, 8.0)
	world.add_room_light(Vector3(-18.0, 3.2, 23.0), Color("dc6c5d"), 1.3, 7.0)

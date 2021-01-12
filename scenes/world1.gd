extends Spatial
const msg = preload("res://scenes/message.tscn")
export var buttons := 2
export var spawn = Vector3(-8,6,8)
export var level = 1

func _ready():
	Global.other_world = get_tree().get_nodes_in_group("otherworld")
	Global.over_world = get_tree().get_nodes_in_group("overworld")
	Global.on_overworld = true
	Global.reset()
	$Player.start()
	$Player.get_node("Menu").visible = false
	var m = msg.instance()
	add_child(m)
func update_buttons():
	buttons -= 1
	if buttons == 0:
		open_door()

func open_door():
	$clear_door.open()

func respawn(player):
	player.transform.origin = spawn
	pass # Replace with function body.

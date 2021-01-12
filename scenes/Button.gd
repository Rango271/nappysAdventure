extends Spatial

var pressed = false
var level = null
signal button_pressed(obj)

func _ready():
	level = get_tree().current_scene

func press():
	if !pressed:
		$AnimationPlayer.play("press")
		pressed = true
		emit_signal("button_pressed",self)#not used...
		level.update_buttons()
func _on_press_area_body_entered(body):
	press()
	pass

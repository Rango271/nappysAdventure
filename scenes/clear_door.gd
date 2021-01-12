extends Spatial

onready var level_clear = preload("res://scenes/level_clear_screen.tscn")

func open():
	$AnimationPlayer.play("open")

func _on_pass_trigger_body_entered(body):
	if body.name.begins_with("Player"):
		var b = level_clear.instance()
		add_child(b)
		b.fade(get_parent().level)
		
	pass 

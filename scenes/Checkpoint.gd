extends Area

var active = false

func _on_Checkpoint_body_entered(body):
	if body.name.begins_with("Player"):
		active = true
		get_parent().spawn = transform.origin
	pass # Replace with function body.

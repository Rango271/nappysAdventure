extends Area


func _on_void_body_entered(body):
	if body.name.begins_with("Player"):
		get_parent().respawn(body)
	pass # Replace with function body.

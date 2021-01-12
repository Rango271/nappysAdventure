extends Control

func _ready():
	yield(get_tree().create_timer(10.0),"timeout")
	queue_free()

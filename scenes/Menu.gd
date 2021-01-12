extends Control


const level1 = "res://scenes/world.tscn"
onready var level_clear = preload("res://scenes/level_clear_screen.tscn")


func _on_START_pressed():
	visible = false
	get_parent().start()

func _on_EXIT_pressed():
	get_tree().quit()


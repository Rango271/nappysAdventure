extends Control

export var level = 1
var menu = null
func fade(le):
	$Tween.interpolate_property($background,"color", Color.transparent, Color.black, 1,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.start()
	level = le
func fade_out():
	$Tween.interpolate_property($background,"color", Color.black,Color.transparent, 1,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.start()

func change_scene():
	Global.change(level)
	fade_out()
func _on_Tween_tween_all_completed():
	change_scene()
	pass # Replace with function body.

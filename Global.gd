extends Node

var on_overworld = true
var other_world
var over_world 

func toggle_world():
	on_overworld = !on_overworld
	for i in other_world:
		if i != null:
			i.set_collision_layer_bit(0,!on_overworld)
			i.visible = !i.visible
	for u in over_world:
		if u != null:
			u.set_collision_layer_bit(0,on_overworld)
			u.visible = !u.visible 

func change(lvl):
	get_tree().current_scene.call_deferred("free")
	if lvl == 1:
		get_tree().change_scene("res://scenes/world2.tscn")
	else:
		get_tree().change_scene("res://scenes/world.tscn")

func reset():
	for i in other_world:
		if i != null:
			i.set_collision_layer_bit(0,false)
			i.visible = false
	for u in over_world:
		if u != null:
			u.set_collision_layer_bit(0,true)
			u.visible = true

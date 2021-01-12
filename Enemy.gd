extends KinematicBody

var path = []
var path_node = 0
var nav
var player
var is_close = false
var is_dead = false
var damage = 1
var can_attack = false
onready var anim = $AnimationPlayer
func _ready():
	nav = get_parent()
	anim.play("idle")
	pass

func _physics_process(delta):
	if !is_dead:
		if is_close:
			$angle.look_at(player.global_transform.origin,Vector3(0,1,0))
			$Skeleton.rotation_degrees.y = $angle.rotation_degrees.y
			if path_node < path.size():
				var dir = (path[path_node] - global_transform.origin)
				if dir.length() < 1:
					path_node += 1
				else:
					move_and_slide(dir.normalized() * 4,Vector3.UP)

func chase_player():
	anim.play("walk")
	if player.is_dead:
		return
	var target = player.global_transform.origin
	path = nav.get_simple_path(global_transform.origin,target)
	path_node = 0

func _on_Area_body_entered(body):
	if !is_close:
		if body.name.begins_with("Player"):
			anim.stop()
			is_close = true
			player = body
	pass

func _on_Area_body_exited(body):
	if body.name.begins_with("Player"):
		is_close = false
		anim.play("idle")
	pass 


func _on_chase_timer_timeout():
	if is_close && !is_dead:
		chase_player()
	pass

func die():
	queue_free()
	pass



func _on_hit_area_body_entered(body):
	if body.name.begins_with("Player"):
		if !is_dead:
			anim.play("death")
			is_close = false
			damage = 0
			is_dead = true
func _on_attack_timer_timeout():
	damage = 1
	if player != null:
		player.hurt(damage)
	if can_attack:
		$attack_timer.start()
	pass

func _on_attack_area_body_entered(body):
	if body.name.begins_with("Player"):
		if !is_dead:
			damage = 1
			player = body
			body.hurt(damage)

	pass 

func _on_attack_area_body_exited(body):
	$attack_timer.stop()
	can_attack = false
	damage = 0
	pass

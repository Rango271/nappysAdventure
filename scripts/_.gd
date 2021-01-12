
extends KinematicBody


const MAX_SLOPE_ANGLE := 45.0
const dust := preload("res://scenes/particle_land.tscn")
const UP := Vector3.UP
const RUN_SPEED := 14
const MAX_GRAVITY := -25
const ACCEL := 6.0
const collision_shape := preload("res://assets/Player_new/collision/player_col.tres")

onready var stand_collision := $collision
onready var dive_collision := $dive_collision
onready var anim := $AnimationTree
onready var wall_rays := $Skeleton/wall_rays/wall_ray_up
onready var camera := $cam_pivot/camera
onready var cam_pivot := $cam_pivot
onready var skeleton := $Skeleton
onready var ik_neck := $Skeleton/spine
onready var hud := $HUD 
"""
Particles
"""
onready var trail_particles := $Skeleton/CPUParticles
onready var wall_particles := $Skeleton/wall_particles
onready var air_particles := $Skeleton/air_particles
#Timers
onready var cam_timer := $Timers/camera_timer
onready var lgjump_timer := $Timers/lngjump_timer
onready var fall_timer := $Timers/fall_timer
onready var wall_timer := $Timers/wall_timer
onready var idle_timer := $Timers/idle_timer
onready var dbjump_timer := $Timers/double_jump_timer
onready var roll_timer := $Timers/roll_timer
onready var stun_timer := $Timers/stun_timer
onready var inv_timer := $Timers/invul_timer
onready var hurt_timer := $Timers/hurt_timer
onready var dead_timer := $Timers/dead_timer
"""
Raycasts
"""
onready var ray := $RayCast
onready var motion_ray := $motion_ray
onready var shadow_ray := $shadow_ray
onready var edge_ray := $Skeleton/edge/edge_ray
"""
Shadow
"""
onready var shadow_shape := $bottom_shadow
var velocity: Vector3 = Vector3.ZERO
var is_jumping: bool = false
var has_moved: bool = false
var mov_speed:float = 0
var accel:int = 6
var gravity:float = 50
var reset:bool = false
var hv := Vector3.ZERO
var state
var can_wall_jump := false
var _dir := Vector3.ZERO
var is_moving := false
var is_longJump := false
var count := 0
var ground_level := 0
var friction := 1.0
var on_ground := false
var st := 0
var current_wall = null
var c_normal
var can_doublejump := false
var is_doubleJump := false
var is_airjump := false
var jump_count := 0
var zx_speed := 0
var is_diving := false
var is_rolling := false
var momentum := Vector3.ZERO
var was_on_plat := false
var is_on_plat := false
var is_controling := false
var last_plat = null
var stay_on_plat := false
var can_airjump := false
var height := 0
var dir := Vector3.ZERO
var is_hurt := false
var health := 3
var is_dead := false
var wall_jump_dir := Vector3.ZERO
var cur_enemy = null
var can_hang := false
var cur_edge = null
var is_climbing := false
var state_list = {
	'IDLE':0,
	'RUN':1,
	'JUMP':2,
	'LONGJUMP':3,
	'FALL':4,
	'WALL':5,
	'WALL_JUMP':6,
	'TRIPLE_JUMP':7,
	'DIVE':8,
	'AIR_JUMP':9,
	'ROLL':10,
	'STUN':11,
	'HURT':12,
	'DEAD':13,
	'HANG':14,
	'CLIMB':15
}

func _ready():
	state = state_list.IDLE
	shadow_shape.set_as_toplevel(true)

	pass
	
func is_near_wall():
	for rays in wall_rays.get_children():
		if rays.is_colliding():
			var dot = abs(rad2deg(rays.get_collision_normal().y))
			if dot < 20:
				return true
	return false

func _process(delta):
	cam_pivot.rotation_degrees.y -= Input.get_joy_axis(0,2) * 2
func _input(event):
	if(Input.is_action_pressed("change_zoom")):
		camera.mouse_motion = false
		camera.set_view()
	
	if event is InputEventMouseMotion || event is InputEventScreenDrag || Input.is_action_pressed("joy_camera"):
		cam_timer.stop()
		cam_timer.start()
		has_moved = false
		camera.mouse_motion = true

		if event is InputEventMouseMotion:
			cam_pivot.rotation_degrees.y -= event.relative.x * 0.1
	
	if(Input.is_action_just_pressed("ui_cancel")):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


	if(Input.is_action_pressed("ui_select")):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if(Input.is_action_pressed("ui_end")):
		transform.origin = Vector3(-30,12,-7)
		rotation = Vector3()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen 
func get_current_wall(check = false):
	if check:
		if current_wall != wall_rays.get_collider():
			return false
	else:
		current_wall = wall_rays.get_collider()
	return true
func analog_force_change(inForce, inAnalog):
	print(inForce)
	if inForce.x < -0.2:
		Input.action_press("left")
	else:
		Input.action_release("left")
	
	if inForce.x > 0.2:
		Input.action_press("right")
	else:
		Input.action_release("right")
	if inForce.y > 0.2:
		Input.action_press("foward")
	else:
		Input.action_release("foward")
	if inForce.y < -0.2:
		Input.action_press("back")
	else:
		Input.action_release("back")

# Gets Input and updates the direction
func update_direction():
#	Engine.time_scale = 1
	if camera.current:
		var cam_dir = camera.get_global_transform()
		if(Input.is_action_pressed("foward")):
			is_controling = true
			_dir += -cam_dir.basis[2]
		elif(Input.is_action_pressed("back")):
			is_controling = true
			_dir += cam_dir.basis[2]
		if(Input.is_action_pressed("left")):
			is_controling = true
			_dir += -cam_dir.basis[0]
		elif(Input.is_action_pressed("right")):
			is_controling = true
			_dir += cam_dir.basis[0]
		
# Applies gravity
func apply_gravity(delta:float):
	if hv.y > MAX_GRAVITY:
		hv.y -= 50 * friction * delta
"""
 Main jump function,
 Power is how high it will jump
 jspeed is additional speed with will be added to the current speed minus the momemtum
"""
func jump_now(power, no_stop = false, jspeed = 0)->void:
	hv.y = power
	if !is_doubleJump:
		is_jumping = true
	is_longJump = no_stop
	mov_speed = (velocity * Vector3(1,0,1)).length() - momentum.length() + jspeed
	if no_stop:
		mov_speed = RUN_SPEED + jspeed
"""
 rotate the mesh
"""
func rot_skeleton(delta:float,rot_speed = 6)->void:
	skeleton.rotation.y = lerp_angle(skeleton.rotation.y,atan2(_dir.x,_dir.z), rot_speed * delta)
	dive_collision.rotation.y = skeleton.rotation.y
	dive_collision.transform.origin.x = skeleton.transform.origin.x
	dive_collision.transform.origin.z = skeleton.transform.origin.z
func apply_velocity(delta):
	pass
func create_dust(amount = 3)->void:
	var angle = 0
	for d in amount:
		d = dust.instance()
		add_child(d)
		d.transform.origin.y += 1
		d.rotation_degrees.y = angle
		angle += 45
func _physics_process(delta):
	var jump = 21
	c_normal = wall_rays.get_collision_normal().round()
	on_ground = is_on_floor()
	height = shadow_ray.transform.origin.y - to_local(shadow_ray.get_collision_point()).y
	if shadow_ray.is_colliding():
		shadow_shape.visible = true
		shadow_shape.global_transform.origin = shadow_ray.get_collision_point()
		if on_ground:
			shadow_shape.transform.origin = transform.origin
	else:
		shadow_shape.visible = false
	var dir_cross = Vector3.ZERO

	if st == state_list.WALL:
		_dir.y = 0
		_dir = _dir.normalized()
		dir_cross = _dir.cross(c_normal)
		if abs(dir_cross.y) >= 0.6 &&  abs(dir_cross.y) <= 1:
			_dir = c_normal.rotated(Vector3.UP,deg2rad(-45) * sign(dir_cross.y))
			_dir = _dir.normalized()
		else:
			_dir = c_normal
		wall_jump_dir = _dir
	elif ![state_list.WALL_JUMP,state_list.HANG].has(st):
		dir = _dir
		dir.y = 0
		dir = dir.normalized()
	if dir.length() > 0.1:
		is_moving = true
	else:
		is_moving = false
	
	_dir.y = 0
	_dir = _dir.normalized()

	if on_ground:
		momentum = Vector3.ZERO
		if was_on_plat:
#			velocity = Vector3.ZERO
#			mov_speed = 0
			was_on_plat = false
		if is_jumping && !is_doubleJump:
			dbjump_timer.start()
			if jump_count == 3:
				jump_count = 0
		elif is_doubleJump:
			is_doubleJump = false
			dbjump_timer.stop()
			jump_count = 0
		if dbjump_timer.is_stopped():
			jump_count = 0
#		if st == state_list.FALL && fall_timer.is_stopped():
#			create_dust()
		hv.y = velocity.y
		is_jumping = false
		can_wall_jump = false
		is_longJump = false
	else:
#		if was_on_plat:
#			if !is_controling && motion_ray.get_collider() == last_plat:
#				if motion_ray.get_collider() != null && motion_ray.get_collider().orientation != "Vertical":
#					accel = 60
#		if is_jumping && st != state_list.WALL_JUMP:
#			accel = 3
#			if st == state_list.DIVE:
#				accel = 8
		if velocity.y < -3:
			if ![state_list.WALL_JUMP,state_list.WALL,state_list.DIVE,state_list.ROLL,state_list.LONGJUMP].has(st):
				accel = 1
			if fall_timer.is_stopped() && st != state_list.FALL && st != state_list.WALL && st != state_list.LONGJUMP:
				fall_timer.start()
	if Input.is_action_just_pressed("roll"):
		if velocity.length() > 6:
			if on_ground:
				lgjump_timer.start()
				roll_timer.start()
	if Input.is_action_just_pressed("attack"):
		if is_moving:
			if !on_ground:
				if dir.dot(velocity) > 0:
					if velocity.y <= 2:
						is_diving = true
			else:
				if !roll_timer.is_stopped():
					is_rolling = true
					roll_timer.start()
	if Input.is_action_just_released("jump"):#Interrupt JUMP
		$Input/jump_force_timer.stop()
		if !is_doubleJump && st != state_list.AIR_JUMP:
			if velocity.y >= 5:
				if velocity.y >= jump - 10:
					hv.y = 15
	if Input.is_action_pressed("jump"):
		if $Input/jump_force_timer.is_stopped():
			$Input/jump_force_timer.start()
	if Input.is_action_just_pressed("jump") && !is_dead && ![state_list.STUN,state_list.HURT].has(st):
		if on_ground:
			was_on_plat = check_plat()
			if is_on_plat:
				if is_controling:
					stay_on_plat = false
				else:
					stay_on_plat = true
			last_plat = motion_ray.get_collider()
			if !dbjump_timer.is_stopped() && zx_speed > 7 && jump_count == 2:
				is_doubleJump = true
				jump_now(jump + 12,false)
			elif lgjump_timer.is_stopped():
				if jump_count == 0:
					jump_now(jump,false)
				elif jump_count == 1:
					jump_now(jump + 4,false)
				trail_particles.emitting = false
				is_doubleJump = false
			else:
				is_longJump = true
				jump_now(jump - 3, true,50)
				is_doubleJump = false
		else:
			if can_hang:
				is_climbing = true
			if wall_rays.is_colliding() && wall_timer.is_stopped():
				can_wall_jump = true
			if $Timers/airjump_timer.is_stopped():
				$Timers/airjump_timer.start()
				is_airjump = false
			else:
				if can_airjump:
					is_airjump = true
		

#				anim.set("parameters/anim_state/current",2)
	set_anim(st, delta)
	velocity = lerp(velocity,dir * (mov_speed + momentum.length())  , delta * accel)
	velocity.y = hv.y * friction
	velocity = move_and_slide(velocity - get_floor_normal() * 6,UP)
	zx_speed = (velocity * Vector3(1,0,1)).length() 
	
	if !on_ground:
		if is_on_plat && stay_on_plat && !is_controling:
			if check_plat(true):
				transform.origin.x = motion_ray.get_collider().get_node("pivot").global_transform.origin.x
				transform.origin.z = motion_ray.get_collider().get_node("pivot").global_transform.origin.z
#		if check_plat(true) && was_on_plat:
#			bruh = motion_ray.get_collider().get_platform_velocity()
#			momentum = bruh * Vector3(1,0,1)
#			if _dir == Vector3.ZERO:
#				_dir = _dir +  momentum
#		else:
#			momentum = Vector3.ZERO
		rotation_degrees = lerp(rotation_degrees,Vector3(), delta * 8)
	var normal = get_floor_normal()
	if normal.y > 0.8 && st != state_list.ROLL:
		var xform = align_y(global_transform,normal)
		global_transform = global_transform.interpolate_with(xform,0.1)
	#DEBUG SCREEN
	#TODO: CREATE A SEPARATE OVERLAY FOR THIS
	$label_state.text = str(state_list.keys()[st]) + "\nFPS: " + str(Engine.get_frames_per_second())
	if true:
		
		$Control/Floor.bbcode_text = (
			fstring("Height", height) +
			fstring("canhang",can_hang) + 
			fstring("Velocity",velocity)+
			fstring("hv",[hv.y, friction])+
			fstring("On Floor", on_ground) + fstring("Current direction", dir) +
			fstring("Pendent direction", _dir) + fstring("Skeleton Basis",skeleton.transform.basis.x) +
			fstring("Skel dot Dir", skeleton.transform.basis.x.dot(_dir))
		)
		var text = $Control/Floor.bbcode_text
		text = text.replace("True","[color=lime]True[/color]")
		text = text.replace("False","[color=red]False[/color]")
		$Control/Floor.bbcode_text = text
	has_moved = is_moving
func check_plat(check = false)->bool:
	var col = motion_ray.get_collider()
	if col is KinematicBody:
		if motion_ray.get_collider().has_method("get_platform_velocity"):
			if check:
				return true if col == last_plat else false
			return true
	return false
func fstring(string:String, value)->String:
	return "\n" +  str(string) + ":  " + str(value) 
func start_wall_timer()->void:
	if wall_timer.is_stopped():
		wall_timer.start()
"""
handle animations
"""
func set_anim(state,delta)->void:
	var blend_amount = anim.get("parameters/idle_run/blend_amount")
	var add_amount = anim.get("parameters/Add2/add_amount")
	var bored = 0
	var tl = idle_timer.time_left
	if !idle_timer.is_stopped():
		if tl < 20 && tl > 17:
			bored = 1
		elif  tl < 10 && tl > 0:
			bored = 2
	match state:
		state_list.CLIMB:
			anim.set("parameters/anim_state/current",1)
			anim.set("parameters/Add2/add_amount",lerp(0,1,delta * 8))
		state_list.HANG:
			anim.set("parameters/anim_state/current",10)
		state_list.DEAD:
			anim.set("parameters/life_state/current",1)
		state_list.IDLE:
			anim.set("parameters/anim_state/current",0)
			anim.set("parameters/idle_trans/current",bored)
			anim.set("parameters/idle_run/blend_amount", lerp(blend_amount,1,delta * 8))
		state_list.RUN:
			anim.set("parameters/anim_state/current",0)
			anim.set("parameters/idle_run/blend_amount", lerp(blend_amount,0,delta * 8))
		state_list.JUMP:
#			anim.set("parameters/jump_blend/blend_amount",0)
			anim.set("parameters/Add2/add_amount",0.5)
			if jump_count == 2:
				anim.set("parameters/anim_state/current",4)
			else:
				anim.set("parameters/anim_state/current",1)
		state_list.LONGJUMP:
			anim.set("parameters/anim_state/current",2)
		state_list.FALL:
#			anim.set("parameters/jump_blend/blend_amount",0)
			anim.set("parameters/anim_state/current",1)
			anim.set("parameters/Add2/add_amount",lerp(add_amount,1,delta * 8))
		state_list.WALL:
			anim.set("parameters/Transition/current",0)
			anim.set("parameters/anim_state/current",5)
			anim.set("parameters/wall_seek/seek_position",0.71)
		state_list.WALL_JUMP:
			anim.set("parameters/anim_state/current",5)
			anim.set("parameters/Transition/current",1)
			anim.set("parameters/wall_jump_seek/seek_position",-1)
#			anim.set("parameters/jump_blend/blend_amount",0)
		state_list.TRIPLE_JUMP:
			anim.set("parameters/anim_state/current",3)
		state_list.DIVE:
			anim.set("parameters/anim_state/current",6)
		state_list.AIR_JUMP:
			anim.set("parameters/anim_state/current",9)
func align_y(xform, newy):
	newy.y = clamp(newy.y, 0.9, 1)
	xform.basis.y = newy
	xform.basis.x = -xform.basis.z.cross(newy)
	xform.basis = xform.basis.orthonormalized()
	return xform
func _on_Timer_timeout():
	if has_moved:
		var camera = get_node("cam_pivot/camera")
		camera.set_as_toplevel(true)
		camera.mouse_motion = false
func die():
	pass
func hurt(damage:float)->void:
	if is_dead:
		return
	if inv_timer.is_stopped() && damage != 0:
		inv_timer.start()
		anim.set("parameters/inv_add/add_amount",1)
		is_hurt = true
		health -= damage
		health = clamp(health,0, 3)
		hud.update_health(health)
		if health == 0:
			dead_timer.start()
			hud.fade_in()
			is_dead = true
	pass

func _on_invul_timer_timeout()->void:
	anim.set("parameters/inv_add/add_amount",0)
	$Skeleton/Character.visible = true
	$Skeleton/Face.visible = true
	$Skeleton/Shoe.visible = true
	$Skeleton/Shoe2.visible = true
	is_hurt = false
	pass

func _on_dead_timer_timeout():
	hud.fade_out()
	pass

func hold_edge():
	_dir = -edge_ray.get_collision_normal()
	skeleton.rotation.y = atan2(_dir.x,_dir.z)
	if cur_edge != null:
		transform.origin.y = cur_edge.global_transform.origin.y - 2.2
	pass
func swing_edge(delta:float):
	
	pass
func _on_edge_area_entered(area):
	cur_edge = area
	can_hang = true
	pass 

func _on_edge_area_exited(area):
	can_hang = false
	pass 

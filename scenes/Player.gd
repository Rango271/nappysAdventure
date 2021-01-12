extends KinematicBody

export var SPEED = 10.0
export var GRAVITY = 45.0
export var ACCEL = 6.0
export var MAX_FALL = -30.0
var states = {
	'IDLE':0,
	'RUN':1,
	'JUMP':2,
	'FALL':3,
	'DEAD':4
}
var velocity = Vector3.ZERO
var direction = Vector3.ZERO
var gv = Vector3.ZERO
var mov_speed = 0
var state = 0
var on_ground = false
var jump_count = 0
var can_airjump = false
var is_moving = false
var started = false
var is_dead = false
onready var camera = $cam_pivot/Camera
onready var over = preload("res://assets/World Enviroments/overworld.tres")
onready var other = preload("res://assets/World Enviroments/otherworld.tres")
onready var anim = $AnimationTree
func _ready():
	set_as_toplevel(true)

func hurt(damage):
	get_parent().respawn(self)
func _input(event):
	if !started:
		return
	if event is InputEventMouseMotion:
		$Timers/camera_timer.start()
		camera.mouse_motion = true
		$cam_pivot.rotation_degrees.y -= event.relative.x * 0.2
	if Input.is_action_just_pressed("camera"):
		camera.set_view()
	if Input.is_action_just_pressed("change_dim"):
		Global.toggle_world()
		switch_env()
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		started = false
		$Menu.visible = true
	if Input.is_action_just_pressed("attack"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func handle_direction():
	var cam = camera.global_transform
	if Input.is_action_pressed("ui_up"):
		direction -= cam.basis[2]
	elif Input.is_action_pressed("ui_down"):
		direction += cam.basis[2]
	if Input.is_action_pressed("ui_left"):
		direction -= cam.basis[0]
	elif Input.is_action_pressed("ui_right"):
		direction += cam.basis[0]

func switch_env():
	if !Global.on_overworld:
		$WE.environment = other
		$AudioStreamPlayer.pitch_scale = 0.5
	else:
		$WE.environment = over
		$AudioStreamPlayer.pitch_scale = 1

func jump():
	$audio.play()
	gv.y += 18
	pass
func start():
	if !$AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	started = true
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func rotate_skeleton(delta):
	$Skeleton.rotation.y = lerp_angle($Skeleton.rotation.y, atan2(direction.x,direction.z), delta * 8)
func _physics_process(delta):
	if !started:
		return
	on_ground = is_on_floor()
	direction = Vector3.ZERO
	handle_direction()
	if direction.length() > 0.1:
		is_moving = true
	else:
		is_moving = false
	
	if is_moving:
		rotate_skeleton(delta)
	mov_speed = SPEED
	if on_ground:
		jump_count = 0 
		gv.y = velocity.y
	else:
		if velocity.y > MAX_FALL:
			gv.y -= GRAVITY * delta
	
	if Input.is_action_just_pressed("ui_accept"):
		if on_ground:
			jump()

	velocity = lerp(velocity, direction * mov_speed, delta * ACCEL)
	velocity.y = gv.y
	velocity = move_and_slide(velocity - get_floor_normal() * 6, Vector3.UP)
	var normal = get_floor_normal()
	if normal.y > 0.8:
		var xform = align_y(global_transform,normal)
		global_transform = global_transform.interpolate_with(xform,0.1)
	pass

#handle animations
func set_anim(st):
	match st:
		states.IDLE:
			anim.set("parameters/anim_state/current", 0)
		states.RUN:
			anim.set("parameters/anim_state/current", 1)
		states.JUMP:
			anim.set("parameters/anim_state/current",2)

func align_y(xform, newy):
	newy.y = clamp(newy.y, 0.9, 1)
	xform.basis.y = newy
	xform.basis.x = -xform.basis.z.cross(newy)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _on_camera_timer_timeout():
	camera.mouse_motion = false
	pass # Replace with function body.

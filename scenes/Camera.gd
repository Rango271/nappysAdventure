extends Camera

var distance = 8.0
var height = 6.0
var mouse_motion = false
var mode = NEAR
var dis:float = 0
var hei:float = 0
#onready var tween = $Tween
export var speed = 4
enum {
	NEAR, MEDIUM, FAR
}

func _ready():
	set_physics_process(true)
	set_as_toplevel(true)
	#add_exception(get_parent().get_parent())
	_physics_process(0)
	set_view()

#func set_fov(fv):
#	tween.interpolate_property(self,"fov", fov, fv, 0.25,Tween.TRANS_LINEAR,Tween.EASE_IN)
#	tween.start()
func set_view():
	if mode == NEAR:
		distance = 12.0
		height = 4.0
	if mode == MEDIUM:
		distance = 18.0
		height = 6.0
#	if mode == FAR:
#		distance = 18.0
#		height = 6.0
	if mode <= 1:
		mode += 1
	else:
		mode = 0
func _physics_process(delta):
	if true:
		rotation.z = 0
		rotation.x = 0
#		if Input.is_key_pressed(KEY_0):
#			dis += 0.1
#			distance = dis
#		if Input.is_key_pressed(KEY_9):
#			dis -= 0.1
#			distance = dis
#		if Input.is_key_pressed(KEY_8):
#			hei += 0.1
#			height = hei
#		if Input.is_key_pressed(KEY_7):
#			hei -= 0.1
#			height = hei
		var target = get_parent().get_global_transform().origin
		var pos = get_global_transform().origin
		var point = get_parent().get_node("point")
		var offset = Vector3()
		var rotat = get_parent().get_parent().get_node("Skeleton").rotation_degrees.y
		if abs(rotat) > 360:
			rotat = fmod(rotat,360)
		offset = pos - target
		
		offset = offset.normalized() * distance
		offset.y = lerp(offset.y,height,0.25)
		offset.y = clamp(offset.y,0,height)

		pos = target + offset
		
		if mouse_motion:
			pos.x = point.global_transform.origin.x
			pos.z = point.global_transform.origin.z
		else:
#			get_parent().rotation_degrees.y = -rotation_degrees.y
			point.global_transform.origin.x = pos.x
			point.global_transform.origin.z = pos.z
		global_transform.origin = lerp(global_transform.origin, pos,delta * 8)
		#global_transform.origin = pos
		$aux_pivot.look_at(target,Vector3.UP)
		rotation_degrees.y += $aux_pivot.rotation_degrees.y
		
		#look_at(target,Vector3.UP)
		#rotation_degrees.x = current_y
		#look_at_from_position(pos, target, Vector3(0,1,0))

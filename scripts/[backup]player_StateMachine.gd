extends StateMachine
# Based on Game Endeavor's State Machine
var p
func _ready():
	p = get_parent()
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("longjump")
	add_state("fall")
	add_state("wall")
	add_state("wall_jump")
	add_state("double_jump")
	add_state("dive")
	add_state("air_jump")
	add_state("roll")
	add_state("stun")
	add_state("hurt")
	add_state("dead")
	add_state("hang")
	add_state("climb")
	call_deferred("set_state", states.idle)
	
func _state_logic(delta):
	if !p.on_ground: 
		p.apply_gravity(delta)
	if ![states.longjump,states.wall, states.roll,states.dive,states.hang,states.climb].has(state):
		p.mov_speed = p.RUN_SPEED
	match state:
		states.roll:
			p.mov_speed = p.RUN_SPEED * 1.5
		states.wall:
			if p.velocity.y <= -5:
				p.wall_particles.emitting = true
		states.longjump:
			p.mov_speed = p.RUN_SPEED * 1.5
		states.hang:
			if abs(round(p.skeleton.transform.basis.x.dot(p._dir))) == 1:
				p.anim.set("parameters/Add2 3/add_amount",1)
				p.move_and_slide(p._dir * 4 * p.skeleton.transform.basis.x.abs())
				if sign(p.skeleton.transform.basis.x.dot(p._dir)) == -1:
					p.anim.set("parameters/hang_tran/current",1)
				else:
					p.anim.set("parameters/hang_tran/current",2)
			else:
				p.anim.set("parameters/hang_tran/current",0)
		
				
	if ![states.longjump,states.climb,states.wall_jump,states.double_jump,states.dive,states.hurt,states.dead,states.stun].has(state):
		if p.is_controling || !p.was_on_plat:
			if state != states.longjump:
				p._dir = Vector3.ZERO
		p.is_controling = false
		p.update_direction()
	#Apply gravity only when on air
	if (p.is_controling || state == states.wall_jump) && state != states.wall && state != states.hang:
		if state == states.wall_jump:
			p.rot_skeleton(delta,4)
		else:
			p.rot_skeleton(delta)


func _get_transition(delta):
	match state:
		states.idle:
			if p.is_hurt:
				return states.hurt
			if !p.on_ground:
				if p.velocity.y > 0:
					return states.jump
				elif p.velocity.y < 0:
					return states.fall
			elif p.is_moving:
				return states.run
			if p.idle_timer.is_stopped():
				 p.idle_timer.start()
				
		states.run:
			if !p.on_ground:
				if p.velocity.y > 0:
					if p.is_longJump:
						return states.longjump
					elif p.is_doubleJump:
						return states.double_jump
					return states.jump
				elif p.velocity.y < 0:
					return states.fall
			else:
				 
				if p.is_hurt:
					return states.hurt
				if !p.is_moving:
					return states.idle
				if p.is_rolling:
					return states.roll
		states.jump:
			if p.on_ground:
				return states.idle
			elif p.velocity.y <= 3:
				if p.can_hang:
					return states.hang
				if p.is_airjump:
					return states.air_jump
				if p.is_diving:
					return states.dive
				if p.velocity.y <= 0:
					if p.wall_rays.is_colliding() && p.height >= 4:
						return states.wall
				return states.fall
		states.hang:
			if p.is_climbing:
				return states.climb
			if p.skeleton.transform.basis.z.dot(p._dir) <= -0.8:
				p.start_wall_timer()
				p.can_wall_jump = false
				return states.fall
			if !p.can_hang:
				return states.fall
		states.climb:
			if p.on_ground:
				return states.run
		states.dive:
			if p.on_ground:
				p.velocity *= 0.5
				return states.run
			if p.is_on_wall():
				return states.stun
		states.longjump:
			if p.on_ground:
				return states.idle
			if p.is_on_wall():
				return states.hurt
			if p.is_airjump:
				return states.air_jump
		states.double_jump:
			if p.on_ground:
				return states.idle
#			if p.wall_rays.is_colliding() && !p.get_current_wall(true) && p.can_wall_jump:
#				return states.wall
			elif p.velocity.y <= 0:
				if p.can_hang:
					return states.hang
				if p.wall_rays.is_colliding():
					return states.wall
				return states.fall
		states.fall:
			if p.on_ground:
				return states.idle
			elif p.is_diving:
				return states.dive
			if p.velocity.y <= 0:
				if p.can_hang:
					return states.hang
				if p.wall_rays.is_colliding() && p.height >= 4 && p.wall_timer.is_stopped():
					return states.wall
				if p.is_airjump:
					return states.air_jump
		states.wall:
			if p.on_ground:
				return states.idle
			if p.can_wall_jump:
				return states.wall_jump
			if !p.wall_rays.is_colliding():
				return states.fall
			if p.can_hang:
				return states.hang
		states.wall_jump:
			if p.on_ground:
				return states.idle
#			elif p.wall_rays.is_colliding() && !p.get_current_wall(true) && p.can_wall_jump:
#				return states.wall
			elif p.velocity.y <= 0:
				if p.can_hang:
					return states.hang
				if p.is_diving:
					return states.dive
				if p.wall_rays.is_colliding():
					return states.wall
				if p.velocity.y <= -5:
					if p.is_airjump:
						return states.air_jump
					return states.fall
		states.roll:
			if p.is_jumping:
				return states.jump
			if p.roll_timer.is_stopped():
				p.is_rolling = false
				return states.run
		states.stun:
			if p.stun_timer.is_stopped():
				if p.on_ground:
					return states.idle
				else:
					return states.fall
		states.air_jump:
			if p.on_ground:
				return states.idle
			if p.velocity.y <= 0:
				if p.can_hang:
					return states.hang
				return states.fall
		states.hurt:
			if p.is_dead:
				return states.dead
			if p.hurt_timer.is_stopped():
				return states.idle
			if p.on_ground:
				p.velocity *= 0.1
		states.dead:
			if !p.is_dead:
				return states.idle

	return null
	
func _enter_state(new_state,old_state):
	p.st = new_state
	match new_state:
		states.climb:
			p._dir = -p.edge_ray.get_collision_normal()
			p.jump_now(18,true)
		states.dead:
			p.collision_shape.set("height",0.5)
			p.anim.set("parameters/inv_add/add_amount",0)
			p.velocity = Vector3.ZERO
			p._dir = Vector3.ZERO
		states.air_jump:
			p.can_airjump = false
			p.is_airjump = false
			p.create_dust()
			p.velocity *= 0.75
#			p._dir = Vector3.ZERO
			p.hv.y = 0
			p.jump_now(23,false,0)
		states.wall:
			p.skeleton.rotation.y = atan2(-p.c_normal.x, -p.c_normal.z)
			p.velocity = Vector3.ZERO 
			p.can_airjump = true
			p.is_jumping = false
			p.get_current_wall()
			p.wall_friction = 0.75
			p.mov_speed = 0
			p.hv.y = 0
		states.longjump:
			p.wall_friction = 1
			p.accel = 6
			if p.jump_count == 0:
				p.jump_count += 1
		states.idle:
			p.is_airjump = false
			p.can_airjump = true
			p.accel = 6
			p.is_diving = false
			p.wall_friction = 1
			p.current_wall = null
			p.idle_timer.start()
		states.run:
			p.can_airjump = true
			p.trail_particles.emitting = true
			p.accel = 6
		states.wall_jump:
			p._dir = p.wall_jump_dir
			p.dir = p.wall_jump_dir
			p.accel = 6
			p.can_wall_jump = false
			p.jump_count = 0
			p.jump_now(21,false,1)
		states.double_jump:
			p.anim.set("parameters/dbj_seek/seek_position",0.4)
		states.jump:
			p.accel = 3
			if p.zx_speed > 4:
				p.jump_count += 1
		states.dive:
#			p.rot_skeleton(1,60)
			p.can_airjump = false
			p.dive_collision.disabled = false
			p.stand_collision.disabled = true
			p.create_dust()
			p.accel = 16
			p.collision_shape.set("height",0.5)
			if p.jump_count == 2:
				p.jump_count = 0
#			p.hv.y = 0
#			p.velocity = Vector3.ZERO
			p.wall_friction = 0
			p.jump_now(18,true,3)
			p.wall_friction = 1
		states.roll:
			p.accel = 6
			p.roll_timer.start()
			if old_state != states.dive:
				p.collision_shape.set("height",0.1)
			p.anim.set("parameters/roll_seek/seek_position",0.5)
			p.anim.set("parameters/anim_state/current",7)
		states.stun:
#			p.collision_shape.set("height",0.5)
			p.is_controling = false
			p.is_diving = false
			p.is_rolling = false
			p.accel = 6
			p._dir = Vector3.ZERO
			p.velocity *= -1
			p.anim.set("parameters/stun_seek/seek_amount",0.3)
			p.anim.set("parameters/stun_trans/current",0)
			p.anim.set("parameters/anim_state/current",8)
			p.stun_timer.start()
		states.hurt:
			p.hurt_timer.start()
			p.is_controling = false
			p.is_diving = false
			p.is_rolling = false
			p.accel = 1
			p._dir *= -1
			p.anim.set("parameters/stun_seek/seek_amount",0.3)
			p.anim.set("parameters/stun_trans/current",0)
			p.anim.set("parameters/anim_state/current",8)
		states.hang:
			p.mov_speed = 0
			p.hold_edge()
			p.wall_friction = 0
			p.velocity = Vector3.ZERO
			pass
func _exit_state(old_state, new_state):
	match old_state:
		states.climb:
			p.is_climbing = false
		states.hang:
			p.wall_friction = 1
			p.can_hang = false
		states.wall:
			p.wall_friction = 1
			p.wall_particles.emitting = false
		states.idle:
			p.idle_timer.stop()
		states.run:
			p.trail_particles.emitting = false
		states.longjump:
			p.lgjump_timer.stop()
			p.wall_friction = 1
		states.dive:
			p.dive_collision.disabled = true
			p.stand_collision.disabled = false
			p.is_diving = false
			p.collision_shape.set("height",1.86)
		states.roll:
			p.camera.set_fov(70)
			p.collision_shape.set("height",1.86)
			p.roll_timer.stop()
			p.is_diving = false
			p.is_rolling = false
		states.stun:
			p.collision_shape.set("height",1.86)
		states.hurt:
			p.is_hurt = false
		states.dead:
			p.collision_shape.set("height",1.86)
			p.anim.set("parameters/life_state/current",0)
		
	pass

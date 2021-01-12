extends StateMachine
#Game Endeavour's state machine
func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	call_deferred("set_state",states.idle)
	

#physics process
func _state_logic(delta:float) -> void:
	parent.state = state
	parent.set_anim(state)

#determines when it should change states
func _get_transition(delta:float):
	match state:
		states.idle:
			if parent.on_ground:
				if parent.is_moving:
					return states.run
			else:
				if parent.velocity.y > 0.1:
					return states.jump
				elif parent.velocity.y < 0:
					return states.fall
		states.run:
			if parent.on_ground:
				if !parent.is_moving:
					return states.idle
			else:
				if parent.velocity.y > 0.1:
					return states.jump
				elif parent.velocity.y < 0:
					return states.fall
		states.jump:
			if parent.velocity.y < 0:
				return states.fall
		states.fall:
			if parent.on_ground:
				return states.idle
	return null

func _enter_state(new_state,old_state)-> void:
	pass

func _exit_state(old_state, new_state)-> void:
	pass


extends CharacterBody2D

@export var speed = 400

#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
const ROT_SPEED = 1
#const ACCELERATION = 200
const THROW_SPEED = 100
# Keep between 0-1, 1 is real conservation of momentum, 0 ignores the previous momentum.
const PREV_MOMENTUM_FACTOR = 1


func throw_mass(slice_start: Vector2, slice_end: Vector2, small_area: float):
	# TODO: Find out what direction is towards the small volume
	var throw_dir: Vector2 = Vector2(
		slice_start[1]-slice_end[1],
		slice_start[0]-slice_end[0]
		).normalized()
	
	# TODO: DUMMY, Extract volume of polygon2D
	const DUMMY_INIT_AREA = 20
	velocity = 1/(DUMMY_INIT_AREA-small_area) * (PREV_MOMENTUM_FACTOR * DUMMY_INIT_AREA * velocity - small_area * THROW_SPEED * throw_dir)


func _physics_process(delta: float) -> void:
	
	var rotation_direction := Input.get_axis("roll_left", "roll_right")
	rotation += rotation_direction * ROT_SPEED * delta
	#if Input.is_action_pressed("accel"):
		#velocity += - delta * ACCELERATION * transform.y
		## velocity.y += delta * ACCELERATION * sin(orientation)
	## print(rotation)
	#print(position)

	move_and_slide()

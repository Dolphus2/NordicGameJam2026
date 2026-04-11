extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const TURN_SPEED = 30
const ACCELERATION = 50
var orientation = 0 # In radians. 0 is up


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta

	if Input.is_action_pressed("roll_left"):
		orientation += delta * TURN_SPEED
		
	if Input.is_action_pressed("roll_rigth"):
		orientation -= delta * TURN_SPEED

	if Input.is_action_pressed("accel"):
		velocity += delta * ACCELERATION * Vector2(cos(orientation), sin(orientation))

	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

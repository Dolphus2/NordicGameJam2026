extends CharacterBody2D

@export var speed = 400

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ROT_SPEED = 1
const ACCELERATION = 200


func _physics_process(delta: float) -> void:
	
	var rotation_direction := Input.get_axis("roll_left", "roll_right")
	rotation += rotation_direction * ROT_SPEED * delta

	if Input.is_action_pressed("accel"):
		velocity += - delta * ACCELERATION * transform.y
		# velocity.y += delta * ACCELERATION * sin(orientation)
	print(rotation)

func _physics_process(delta):
	get_input()
	move_and_slide()

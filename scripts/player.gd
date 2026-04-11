extends CharacterBody2D

@export var speed = 400

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ROT_SPEED = 1
const ACCELERATION = 200

func get_determinant(p1, p2) -> float:
	return p1.x * p2.y - p2.x * p1.y

func get_area(points) -> float:
	var A = 0
	for i in range(points.size()):
		A += get_determinant(points[i-1], points[i])
	return abs(A/2)

func sgn(a : float):
	if a > 0: 
		return 1
	return -1

func get_new_points(points : PackedVector2Array, c : Vector2, d : Vector2):
	var inter = []
	for i in range(points.size()):
		var a = points[i-1]
		var b = points[i]

		var oa = get_determinant(d - c, a - c)
		var ob = get_determinant(d - b, d - c)
		var oc = get_determinant(a - b, a - c)
		var od = get_determinant(b - d, b - a)

		if (sgn(oa) != sgn(ob) && sgn(oc) != sgn(od)):
			inter.append((a * ob - b * oa) / (ob - oa))
			## Only runs when the lines intersect.
	
	return inter
	var inter = []
	for i in range(points.size()):
		var a = points[i-1]
		var b = points[i]

		var oa = cross(d,a,c)
		
		# get_determinant(d - c, a - c)
		var ob = cross(d,b,c)
		# get_determinant(d - b, d - c)
		var oc = cross(a,b,c)
		# get_determinant(a - b, a - c)
		var od = cross(b,d,a)
		# get_determinant(b - d, b - a)

		if (sgn(oa) != sgn(ob) && sgn(oc) != sgn(od)):
			inter.append((a * ob - b * oa) / (ob - oa))
			## Only runs when the lines intersect.
	
	return inter

var flag = true

func _physics_process(delta: float) -> void:
	
	var rotation_direction := Input.get_axis("roll_left", "roll_right")
	rotation += rotation_direction * ROT_SPEED * delta

	if Input.is_action_pressed("accel"):
		velocity += - delta * ACCELERATION * transform.y
		# velocity.y += delta * ACCELERATION * sin(orientation)
	# print(rotation)
	# print(position)

	var p1 = Vector2(0, 70)
	var p2 = Vector2(70, 35)
	var points = $CollisionPolygon2D.polygon
	var ans = get_new_points(points, p1, p2)
	if flag:
		print("-----------------")
		print(p1, p2, points)
		print(ans)
		print(get_area(points))
		flag = false

	move_and_slide()

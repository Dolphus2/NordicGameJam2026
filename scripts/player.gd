extends CharacterBody2D

@export var speed = 400

#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
const ROT_SPEED = 1
#const ACCELERATION = 200
const THROW_SPEED = 100
# Keep between 0-1, 1 is real conservation of momentum, 0 ignores the previous momentum.
const PREV_MOMENTUM_FACTOR = 1

# for computing areas
const PI = 3.141592
const G = 200


func throw_mass(slice_start: Vector2, slice_end: Vector2, small_area: float):
	# TODO: Find out what direction is towards the small volume
	var throw_dir: Vector2 = Vector2(
		slice_start[1]-slice_end[1],
		slice_end[0]-slice_start[0]
		).normalized()
	
	var points = $CollisionPolygon2D.polygon
	
	# TODO: DUMMY, Extract volume of polygon2D
	const DUMMY_INIT_AREA = 20
	velocity = 1/(DUMMY_INIT_AREA-small_area) * (PREV_MOMENTUM_FACTOR * DUMMY_INIT_AREA * velocity - small_area * THROW_SPEED * throw_dir)

func get_determinant(p1, p2) -> float:
	return p1.x * p2.y - p2.x * p1.y

func get_area(points) -> float:
	var A = 0
	for i in range(points.size()):
		A += get_determinant(points[i-1], points[i])
	return abs(A/2)

func get_polygon_centroid(poly: PackedVector2Array) -> Vector2:
	var centroid = Vector2.ZERO
	var area = 0.0
	
	for i in range(poly.size()):
		var p1 = poly[i-1]
		var p2 = poly[i]
		var cross_product = get_determinant(p1, p2)
		area += cross_product
		centroid += (p1 + p2) * cross_product

	return centroid / (3.0 * area) # Note: area here is 2 * signed_area

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
			# Only runs when the lines intersect.
			var inter_p = (a * ob - b * oa) / (ob - oa)
			inter.append(inter_p)
	
	return inter
	
func get_cut_polygons(points : PackedVector2Array, c : Vector2, d : Vector2) -> Array[PackedVector2Array]:
	var poly1: PackedVector2Array
	var poly2: PackedVector2Array
	var flag = true
	
	var inter = []
	
	var count = 0
	for i in range(points.size()):
		var a = points[i-1]
		var b = points[i]

		var oa = get_determinant(d - c, a - c)
		var ob = get_determinant(d - b, d - c)
		var oc = get_determinant(a - b, a - c)
		var od = get_determinant(b - d, b - a)
		
		if (sgn(oa) != sgn(ob) && sgn(oc) != sgn(od)):
			# Only runs when the lines intersect.
			var inter_p = (a * ob - b * oa) / (ob - oa)
			inter.append(inter_p)
			# Add the intersection points to the new polygons
			poly1.append(inter_p)
			poly2.append(inter_p)
			flag = not flag
		
		# Could also just record the indices and do this after the loop. 
		if flag: poly1.append(b)
		else: poly2.append(b)
	
	assert(poly1.size() + poly2.size() == points.size() + inter.size()*2)
	
	if inter.size() < 2:
		return [points]
	else: 
		# print(poly1)
		if get_area(poly1) > get_area(poly2):
			return [poly1, poly2] 
		return [poly2, poly1] 

func cut_player(slice_start, slice_end):
	var points = $CollisionPolygon2D.polygon
	var polygons = get_cut_polygons(points, slice_start, slice_end)
	if polygons.size() == 2: # Can optimize this with an earlier check if necessary
		
		# Update collision
		$CollisionPolygon2D.set_deferred("polygon", polygons[0])
		
		# Update texture
		$CollisionPolygon2D/Polygon2D.polygon = polygons[0]
		$CollisionPolygon2D/Polygon2D.set_uv(polygons[0])

		#TODO: Update renderer to match new collision block.
		return polygons[1]
	return null # Think of a better solution.
	
func _on_slicer_slice(slice_start, slice_end) -> void:
	var small_piece = cut_player(slice_start, slice_end)
	if small_piece:
		# TODO: Spawn and render the part that flies off 
		throw_mass(slice_start, slice_end, get_area(small_piece))
		#var points = $CollisionPolygon2D.polygon
		


#### GRAVITY STUFF START ####
func get_radius_center(name) -> Array:
	var space_object : Node2D = get_node("../%s" % [name])
	var space_object_cs : CollisionShape2D = space_object.get_node("Killzone/CollisionShape2D")
	var space_object_cs_radius = space_object_cs.shape.radius
	var space_object_center = space_object.get_position()
	return [space_object_cs_radius, space_object_center]

func get_gravity_contrib(rad_cens, player_pos) -> Vector2:
	var velocity_contribution : Vector2 = Vector2(0, 0)

	for rad_cen in rad_cens:
		var planet_radius = rad_cen[0]
		var planet_pos = rad_cen[1]
		# print("pos: ", pos)
		var diff = player_pos - planet_pos
		var d = pow(diff.x * diff.x + diff.y * diff.y, 0.5) - planet_radius
		var vec = planet_pos - player_pos
		var normed_vec = vec / (vec.x * vec.x + vec.y * vec.y + 1e-3)
		velocity_contribution += G * (planet_radius * planet_radius * PI) / (d * d + 1e-3) * normed_vec

	return velocity_contribution

#### GRAVITY STUFF END ####

var debug_flag = true

func _physics_process(delta: float) -> void:
	
	var rotation_direction := Input.get_axis("roll_left", "roll_right")
	rotation += rotation_direction * ROT_SPEED * delta
	#if Input.is_action_pressed("accel"):
		#velocity += - delta * ACCELERATION * transform.y
		## velocity.y += delta * ACCELERATION * sin(orientation)
	## print(rotation)
	## print(position)

	############# INITIALIZE AREAS START #############
	var black_hole_1_radius_center = get_radius_center("black_hole") # name should match what we called it in the game scene
	var planet_1_radius_center = get_radius_center("planet")
	var asteroid_1_radius_center = get_radius_center("asteroids")

	var rad_cens = [black_hole_1_radius_center, planet_1_radius_center, asteroid_1_radius_center]
	############# INITIALIZE AREAS END #############

	var player_position : Vector2 = get_node(".").get_position()

	velocity += get_gravity_contrib(rad_cens, player_position)
	print(velocity)

	var p1 = Vector2(0, 70)
	var p2 = Vector2(70, 35)
	var points = $CollisionPolygon2D.polygon
	var ans = get_new_points(points, p1, p2)
	if debug_flag:
		print("-----------------")
		print(p1, p2, points)
		print(ans)
		print(get_area(points))
		print("player position: ", player_position)
		print(black_hole_1_radius_center)
		print(planet_1_radius_center)


		debug_flag = false

	move_and_slide()

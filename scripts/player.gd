extends CharacterBody2D

@export var speed = 400

var IS_DEAD = false

const ROT_SPEED = 1
#const ACCELERATION = 200
const THROW_SPEED = 400
# Keep between 0-1, 1 is real conservation of momentum, 0 ignores the previous momentum.
const PREV_MOMENTUM_FACTOR = 1

const MIN_PLAYER_AREA = 5000
var player_area = 1000000

# for computing areas
const PI = 3.141592

# gravitational constant
const G = 0.256
# gravitational power, = 2 if real world
const ALPHA = 1.6
const SPACE_OBJECT_GRAVITY_NAMES = ["black_hole", "white_hole", "planet", "asteroids", "GoalPlanet"]

const seperation_explosion_scene = preload("res://scenes/seperation_particles.tscn")
var sep_exp_container := Node2D.new()
const piece_scene = preload("res://scenes/player_piece.tscn")
var piece_container := Node2D.new()


func _ready() -> void:
	# Make the seperation explosion container
	add_child(sep_exp_container)
	add_child(piece_container)
	player_area = get_area($CollisionPolygon2D.polygon)

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
	var polys: Array[PackedVector2Array] = []
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
	
func get_cut_polygons2(polygon : PackedVector2Array, slice_start : Vector2, slice_end : Vector2) -> Array[PackedVector2Array]:
	"""Cut polygon into smaller polygons by the line CD"""
	# Split with two rectangles. Mask
	if not (Geometry2D.is_point_in_polygon(slice_start, polygon) or Geometry2D.is_point_in_polygon(slice_end, polygon)):
		var slice = (slice_end - slice_start).normalized()
		var norm = Vector2(-slice.y, slice.x) * 10000
		var clip_mask: PackedVector2Array = [
			slice_start + norm, slice_end + norm, slice_end , slice_start
		]
		var polys_a = Geometry2D.clip_polygons(polygon, clip_mask)
		polys_a.append_array(Geometry2D.intersect_polygons(polygon, clip_mask))
		polys_a.sort_custom(func(a, b): return get_area(a) > get_area(b))
		return polys_a
	return [polygon]
	
func get_velocity_pieces(polys, prev_poly, V):
	"""Takes an array of polygons. The first one is the player with the largest area."""
	var M = get_area(prev_poly)
	var v1 = (V * PREV_MOMENTUM_FACTOR) * M # temp
	
	var ms = []
	var vs = []
	
	for i in range(polys.size()):
		var v_norm = ( -1 * (get_polygon_centroid(polys[0]) - get_polygon_centroid(polys[i]))).normalized()
		var v = v_norm * THROW_SPEED
		var m = get_area(polys[i])
		vs.append(v)  # ignore the first one. It will be 0
		ms.append(m)
		v1 -= v*m
		
	v1 /= ms[0]
	vs[0] = v1
	#print("deltaV= v1 - V")
	return vs

func spawn_piece(points: PackedVector2Array, v):
	var piece = piece_scene.instantiate()
	piece_container.add_child(piece)
	piece.spawn(points, v)
	
func explode(inter, v):
	var sep_explosion = seperation_explosion_scene.instantiate()
	sep_exp_container.add_child(sep_explosion)
	sep_explosion.explode(inter, v)

func cut_player(slice_start, slice_end) -> Array[PackedVector2Array]:
	var player_poly = $CollisionPolygon2D.polygon
	var polygons = get_cut_polygons(player_poly, slice_start, slice_end)
	var inter = get_new_points(player_poly, slice_start, slice_end)
	
	if polygons.size() >= 2: # Can optimize this with an earlier check if necessary
		var V = get_velocity()
		var vs = get_velocity_pieces(polygons, player_poly, V) # fully functional, does not modify state
		
		set_velocity(vs[0])
		
		# Update collision
		$CollisionPolygon2D.set_deferred("polygon", polygons[0])
		#location = get_polygon_centroid(polygons[0])
		
		# Update texture
		$CollisionPolygon2D/Polygon2D.polygon = polygons[0]
		$CollisionPolygon2D/Polygon2D.set_uv(polygons[0])
		player_area = get_area(polygons[0])

		# Screen shake
		$Camera2D.start_shake()
		
		for i in range(1, polygons.size()):
			spawn_piece(polygons[i], vs[i])
			explode(inter, vs[i])
		
	assert(polygons.size() >=1)
	return polygons
	
func _on_slicer_slice(slice_start, slice_end) -> void:
	# Cut the player into pieces and apply directional velocity for each piece.
	var polys = cut_player(slice_start, slice_end)
	print(player_area)
	if player_area < MIN_PLAYER_AREA:
		_nothing_left()
		
func _nothing_left():
	$NothingLeft.offset = get_polygon_centroid($CollisionPolygon2D/Polygon2D.polygon)
	$NothingLeft.play()

func _on_nothing_left_animation_finished() -> void:
	# You died. Reload
	get_tree().reload_current_scene()

#### GRAVITY STUFF START ####
func get_radius_center(name) -> Array:
	var space_object : Node2D = get_node("../%s" % [name])
	var space_object_cs : CollisionShape2D = space_object.get_node("Killzone/CollisionShape2D")
	var space_object_cs_radius = space_object_cs.shape.radius
	var space_object_center = space_object.global_position	
	return [space_object_cs_radius, space_object_center]

func get_gravity_contrib(rad_cens : Array, player_pos : Vector2, delta: float) -> Vector2:
	var velocity_contribution : Vector2 = Vector2(0, 0)

	for rad_cen in rad_cens:
		var planet_radius = rad_cen[0]
		var planet_pos = rad_cen[1]
		# print("pos: ", pos)
		var diff = player_pos - planet_pos
		var d = max(1e-3, pow(diff.x * diff.x + diff.y * diff.y, 0.5) - planet_radius)
		var dir = (planet_pos - player_pos).normalized()
		velocity_contribution += G * (planet_radius * planet_radius * PI) / (pow(d, ALPHA) + 1e-3) * dir

	return delta * velocity_contribution

func get_gravity_node_names(node, names):
	for gravity_object in SPACE_OBJECT_GRAVITY_NAMES:
		if "name" in node && gravity_object in node.name:
			names.append(node.get_name())
			break
	for child in node.get_children():
		get_gravity_node_names(child, names)
	return names

#### GRAVITY STUFF END ####

func die():
	IS_DEAD = true
	velocity = Vector2(0,0)
	
	explosion()
	#get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	
func explosion():
	$Explosion.offset = get_polygon_centroid($CollisionPolygon2D/Polygon2D.polygon)
	$Explosion.play()
	$Explosion/AudioStreamPlayer2D.play()
	$Explosion/youdied.play()

func _on_youdied_animation_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

var debug_flag = true

func _physics_process(delta: float) -> void:
	if IS_DEAD:
		velocity = Vector2(0,0)
		return
	
	var rotation_direction := Input.get_axis("roll_left", "roll_right")
	rotation += rotation_direction * ROT_SPEED * delta
	#if Input.is_action_pressed("accel"):
		#velocity += - delta * ACCELERATION * transform.y
		## velocity.y += delta * ACCELERATION * sin(orientation)
	## print(rotation)
	## print(position)

	############# INITIALIZE AREAS START #############
	var rad_cens = []
	var node_names = get_gravity_node_names(get_tree().root, [])
	# print(node_names)
	for name in node_names:
		var rad_cen = get_radius_center(name)
		print(name, " ", rad_cen)
		rad_cens.append(rad_cen)

	############# INITIALIZE AREAS END #############

	var player_position : Vector2 = global_position

	velocity += get_gravity_contrib(rad_cens, player_position, delta)
	#print(velocity)

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


		debug_flag = false

	move_and_slide()		# Update area and check for death 

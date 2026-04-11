extends CPUParticles2D


func explode(inter, small_velocity: Vector2) -> void:
	var p1: Vector2 = inter[0]
	var p2: Vector2 = inter[1]
	var start_position = 0.5 * (p1 + p2)

	# Arbitrarily multiply width with 0.5 because yes.
	var width = 0.5 * p1.distance_to(p2)
	var angle = (small_velocity).angle()

	rotation = angle
	emission_rect_extents = Vector2(0, width)
	position = start_position
	emitting = true
	

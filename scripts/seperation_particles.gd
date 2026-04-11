extends CPUParticles2D


func explode(inter) -> void:
	var inter_vec_0 = Vector2(inter[0])
	var inter_vec_1 = Vector2(inter[1])
	var start_position = 0.5 * (inter_vec_0 + inter_vec_1)

	var width = inter_vec_0.distance_to(inter_vec_1)
	#var angle = 

	#rotation = angle
	emission_rect_extents = Vector2(0, width)
	position = start_position
	emitting = true
	

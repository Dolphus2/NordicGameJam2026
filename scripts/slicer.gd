extends Line2D

var slice_start: Vector2 = Vector2.ZERO
var slice_end: Vector2 = Vector2.ZERO
var dragging: bool = false

# Potential dummy function that can be called do the slicing
func dummy() -> void:
	pass

func _process(delta: float) -> void:
	# Render the line while dragging
	if dragging:	
		clear_points()
		add_point(slice_start)
		add_point(get_global_mouse_position())

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Start dragging
			if event.pressed:
				slice_start = get_global_mouse_position()
				dragging = true
			# Button release
			else: 
				slice_end = get_global_mouse_position()
				dragging = false
				clear_points()
				dummy()
			
			

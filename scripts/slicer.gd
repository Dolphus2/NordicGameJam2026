extends Line2D

var slice_start_screen: Vector2 = Vector2.ZERO
var slice_start: Vector2 = Vector2.ZERO
var slice_end: Vector2 = Vector2.ZERO
var dragging: bool = false

@onready var player = $".."

# Potential dummy function that can be called do the slicing
func dummy() -> void:
	pass

func _process(delta: float) -> void:
	# Render the line while dragging
	if dragging:	
		clear_points()
		# Translate screen to local coords
		add_point(to_local(get_viewport().get_canvas_transform().affine_inverse() * slice_start_screen))
		add_point(get_local_mouse_position())

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Start dragging
			if event.pressed:
				# Screen position
				slice_start_screen = event.position
				dragging = true
			# Button release
			else:
				slice_start = to_local(get_viewport().get_canvas_transform().affine_inverse() * slice_start_screen)
				slice_end = get_local_mouse_position()
				dragging = false
				clear_points()
				dummy()
				# TODO: Make sure to only call throw_mass if the slice goes through the polygon fully
				# TODO: 10.0 is a dummy small area

				player.throw_mass(slice_start, slice_end, 10.0)
			
			

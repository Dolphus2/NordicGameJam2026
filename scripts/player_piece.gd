extends RigidBody2D

func spawn(points, v):
	$CollisionPolygon2D.set_deferred("polygon", points)
	$CollisionPolygon2D/Polygon2D.polygon = points
	$CollisionPolygon2D/Polygon2D.uv = points
	linear_velocity = v
	$AudioStreamPlayer2D.play(1.3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.d
func _process(delta: float) -> void:
	pass

func _process_physics(delta):

	pass


extends Camera2D

const START_STRENGTH: float = 25.0
const SHAKE_FADE: float = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0

func start_shake() -> void:
	# Start the shaking
	shake_strength = START_STRENGTH

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, clamp(SHAKE_FADE * delta,0,1))
		offset = random_offset()
	
func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))



	

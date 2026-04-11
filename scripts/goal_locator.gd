extends Sprite2D

@onready var goal_planet: Node2D = $"../../GoalPlanet"

# TODO: should it instead be the length to 
#the furthest point in the character form origin instead?
const RADIUS = 150
const MAX_SCALE = 0.15
const MIN_SCALE = 0.02

# Which distance we begin to cut and just use max_scale
const MAX_DISTANCE = 5000


var start_distance


func _ready() -> void:
	scale = Vector2(MIN_SCALE, MIN_SCALE)


func _process(delta: float) -> void:
	look_at(goal_planet.position)
	position = Vector2(RADIUS * cos(rotation), RADIUS * sin(rotation))
	
	var cur_distance = global_position.distance_to(goal_planet.position)
	var new_scale = lerp(MIN_SCALE, MAX_SCALE, clamp(1-cur_distance/MAX_DISTANCE, 0.0, 1.0))
	scale = Vector2(new_scale,new_scale)

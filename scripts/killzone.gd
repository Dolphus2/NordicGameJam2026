extends Area2D

@onready var timer: Timer = $Timer

var flag = false

func _on_body_entered(body: Node2D) -> void:
	if flag:
		return

	flag = true
	if body.has_method("die"):
		body.die()

	Engine.time_scale = 0.5
	timer.start()
	

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene() # replace with end scene when created

extends Area2D

var travalled_distance = 0

func _physics_process(delta: float) -> void:
	const SPEED = 1000
	const RANGE = 1200
	#get rotation of bullet
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travalled_distance += SPEED * delta
	
	if travalled_distance > RANGE:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Disable the bullet's own collision immediately so it doesn't hit twice
	set_deferred("monitoring", false) 
	
	if body.has_method("take_damage"):
		body.take_damage()
	
	queue_free()

extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var speed: int = 200

func _on_physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	
	# ONLY set walk velocity if we are not currently dashing
	if not player.is_dashing:
		player.velocity = direction * speed
	
	# Animation Logic
	var anim_name = "walk_front"
	if player.player_direction == Vector2.UP:
		anim_name = "walk_back"
	elif player.player_direction == Vector2.DOWN:
		anim_name = "walk_front"
	elif player.player_direction == Vector2.RIGHT:
		anim_name = "walk_right"
	elif player.player_direction == Vector2.LEFT:
		anim_name = "walk_left"
	
	animated_sprite_2d.play(anim_name)

func _on_next_transitions() -> void:
	# If we stop moving, go back to Idle
	if Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down") == Vector2.ZERO:
		transition.emit("Idle")

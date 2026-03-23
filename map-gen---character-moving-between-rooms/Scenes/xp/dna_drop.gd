extends Area2D

@export var xp_value: int = 1
@export var magnet_range: float = 150.0  # How close you need to be
@export var move_speed: float = 100.0    # Starting speed
@export var acceleration: float = 400.0  # How fast it speeds up while chasing

var player: Player = null
var is_moving: bool = false

func _ready() -> void:
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	# Connect the signal for when you actually touch the gem
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if player == null: return
	
	var dist = global_position.distance_to(player.global_position)
	
	# If player is close enough, start the magnet effect
	if dist < magnet_range:
		is_moving = true
		
	if is_moving:
		# Increase speed over time for that "snap" effect
		move_speed += acceleration * delta
		
		# Move toward the player
		var direction = global_position.direction_to(player.global_position)
		global_position += direction * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.gain_xp(xp_value)
		# Add a little sound or particle effect here later!
		queue_free()

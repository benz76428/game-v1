extends CharacterBody2D

var health = 5

# Preload the DNA Drop scene here so the enemy knows what to drop
# Make sure this path matches where you saved your DNA drop scene!
const DNA_DROP = preload("res://Scenes/xp/dna_drop.tscn") 

@onready var player = get_node("/root/DungeonGenerator/Player")
@export var damage_amount: int = 10
@export var attack_cooldown: float = 1.0 # Waits 1 second between attacks
var can_attack: bool = true

func _ready():
	%Slime.play_walk()
	
func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * 50
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if it's the player AND if the mob is off cooldown
		if collider is Player and can_attack:
			collider.take_damage(damage_amount)
			trigger_attack_cooldown()
			
func trigger_attack_cooldown() -> void:
	can_attack = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	
	can_attack = true
func take_damage():
	health -= 1
	%Slime.play_hurt()
	
	if health <= 0:
		# Use set_deferred to turn off physics immediately 
		# so no more bullets can hit this enemy while it's dying
		$Hitbox.set_deferred("disabled", true)
		
		# Use call_deferred to run the spawn logic safely in the next frame
		call_deferred("_on_death")

func _on_death():
	# 1. Instantiate and setup the DNA drop
	var drop = DNA_DROP.instantiate()
	drop.global_position = global_position
	
	# 2. Instantiate and setup the smoke
	const SMOKE_SCENE = preload("res://Test Assets/smoke_explosion/smoke_explosion.tscn")
	var smoke = SMOKE_SCENE.instantiate()
	smoke.global_position = global_position
	
	# 3. Add them to the room
	var room = get_parent()
	room.add_child(drop)
	room.add_child(smoke)
	
	# 4. Finally, remove the enemy
	queue_free()
	
	# This function runs automatically whenever a physics body touches the Hitbox Area2D
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Check if the thing we just bumped into is the player
	if body == player:
		# Tell the player to take 10 damage! (Change the number to whatever you want)
		if body.has_method("take_damage"):
			body.take_damage(10)

extends CharacterBody2D

var health = 5


const DNA_DROP = preload("res://Scenes/xp/dna_drop.tscn") 

@onready var player = get_tree().get_first_node_in_group("player")
@export var damage_amount: int = 10
@export var attack_cooldown: float = 1.0 
var can_attack: bool = true

func _ready():
	%Slime.play_walk()
	
func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * 50
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# mob attack cooldown
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

		$Hitbox.set_deferred("disabled", true)

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
	

func _on_hitbox_body_entered(body: Node2D) -> void:
	# Check if the thing is the player
	if body == player:

		if body.has_method("take_damage"):
			body.take_damage(10)

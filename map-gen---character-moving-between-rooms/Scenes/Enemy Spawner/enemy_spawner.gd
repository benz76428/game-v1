extends Marker2D
class_name EnemySpawner

@export_group("Enemy Selection")
# Add your enemy scenes here in the inspector
@export var enemy_types: Dictionary = {
	"Demon": preload("res://Scenes/enemies/Demon.tscn"),
	"Slime": preload("res://Scenes/enemies/mob.tscn"),
	"Skeleton": preload("res://Scenes/enemies/enemy_3.tscn")
}

@export_group("Spawn Configuration")
@export var spawn_demon: bool = false
@export var spawn_skeleton: bool = false
@export var spawn_slime: bool = false

func spawn() -> Node2D:
	var valid_enemies = []
	if spawn_demon: valid_enemies.append(enemy_types["Demon"])
	if spawn_skeleton: valid_enemies.append(enemy_types["Skeleton"])
	if spawn_slime: valid_enemies.append(enemy_types["Slime"])
	
	if valid_enemies.is_empty():
		return null

	var enemy_scene = valid_enemies.pick_random()
	var enemy = enemy_scene.instantiate()
	
	# Add to the room
	get_parent().add_child.call_deferred(enemy)
	enemy.global_position = global_position
	
	return enemy # Return the instance for tracking

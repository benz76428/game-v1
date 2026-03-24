extends Marker2D
class_name EnemySpawner

@export_group("Spawn Chances (%)")
@export var demon_chance: float = 10.0
@export var skeleton_chance: float = 30.0
@export var slime_chance: float = 60.0
@export var fast_slime_chance: float = 60.0

var enemy_scenes = {
	"Demon": preload("res://Scenes/enemies/Demon.tscn"),
	"Skeleton": preload("res://Scenes/enemies/enemy_3.tscn"),
	"Slime": preload("res://Scenes/enemies/mob.tscn"),
	"Fast Slime": preload("res://Scenes/enemies/fast_mob.tscn")
}

func spawn() -> Node2D:
	var total_chance = demon_chance + skeleton_chance + slime_chance + fast_slime_chance
	if total_chance <= 0:
		return null # Failsafe if everything is set to 0
		
	# Roll a random number between 0 and the total
	var roll = randf_range(0.0, total_chance)
	var current_step = 0.0
	var chosen_key = ""
	
	# Weighted random selection
	var weights = {"Demon": demon_chance, "Skeleton": skeleton_chance, "Slime": slime_chance, "Fast Slime": fast_slime_chance}
	for key in weights:
		current_step += weights[key]
		if roll <= current_step:
			chosen_key = key
			break
			
	var enemy = enemy_scenes[chosen_key].instantiate()
	
	# Add to the room
	get_parent().add_child.call_deferred(enemy)
	enemy.global_position = global_position
	
	return enemy

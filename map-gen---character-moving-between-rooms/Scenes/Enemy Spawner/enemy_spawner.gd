extends Marker2D
class_name EnemySpawner

@export_group("Spawn Chances (%)")
@export var slime_chance: float = 60.0
@export var fast_slime_chance: float = 60.0

var enemy_scenes = {
	"Slime": preload("res://Scenes/enemies/Test_Slime/mob.tscn"),
	"Fast Slime": preload("res://Scenes/enemies/Test_fast_slime/fast_mob.tscn")
}

func spawn() -> Node2D:
	var total_chance = slime_chance + fast_slime_chance
	if total_chance <= 0:
		return null
		
	
	var roll = randf_range(0.0, total_chance)
	var current_step = 0.0
	var chosen_key = ""
	
	
	var weights = {"Slime": slime_chance, "Fast Slime": fast_slime_chance}
	for key in weights:
		current_step += weights[key]
		if roll <= current_step:
			chosen_key = key
			break
			
	var enemy = enemy_scenes[chosen_key].instantiate()
	
	
	get_parent().add_child.call_deferred(enemy)
	enemy.global_position = global_position
	
	return enemy

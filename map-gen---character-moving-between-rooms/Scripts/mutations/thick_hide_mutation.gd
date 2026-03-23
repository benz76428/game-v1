# thick_hide_mutation.gd
extends Mutation
class_name ThickHideMutation

@export var health_increase: int = 50

func apply_mutation(player: Node2D) -> void:
	# Note: Adjust these variable names to match what is actually in your player.gd
	if "max_health" in player:
		player.max_health += health_increase
		player.current_health += health_increase
		print("Player mutated! Gained ", health_increase, " health.")

func remove_mutation(player: Node2D) -> void:
	if "max_health" in player:
		player.max_health -= health_increase

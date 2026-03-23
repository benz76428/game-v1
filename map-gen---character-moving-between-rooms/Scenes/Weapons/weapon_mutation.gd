# weapon_mutation.gd
extends Mutation
class_name WeaponMutation

@export var weapon_scene: PackedScene

func apply_mutation(player: Node2D) -> void:
	if weapon_scene == null:
		print("ERROR: No weapon scene assigned to this DNA!")
		return
		
	var weapon_instance = weapon_scene.instantiate()
	player.add_child(weapon_instance)
	
	# Hand the weapon to the player's auto-equipper
	if player.has_method("add_weapon"):
		player.add_weapon(weapon_instance)
		print(mutation_name, " given to player!")

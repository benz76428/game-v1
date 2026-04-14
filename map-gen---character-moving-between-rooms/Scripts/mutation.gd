# mutation.gd
extends Resource
class_name Mutation

enum Type {
	PASSIVE,  # Stat changes (Health, Speed, etc.)
	WEAPON,   # Unlocking new primary attacks
	MODIFIER, # Modifying existing attacks (bouncy, piercing, explode)
	DASH      # Changes to your dash mechanic
}

@export var mutation_name: String = "Unknown Mutation"
@export_multiline var description: String = "What does this DNA do?"
@export var icon: Texture2D
@export var mutation_type: Type = Type.PASSIVE


func apply_mutation(player: Node2D) -> void:
	pass

func remove_mutation(player: Node2D) -> void:
	pass

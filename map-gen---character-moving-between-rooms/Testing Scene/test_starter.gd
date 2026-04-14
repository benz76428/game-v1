extends Node

func _ready() -> void:
	# Waits until the Room is fully initialized before calling the function
	get_parent().call_deferred("spawn_enemies")

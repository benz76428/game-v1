extends Node2D
class_name BaseWeapon

@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.5
var can_shoot: bool = true


func shoot(aim_direction: Vector2) -> void:
	pass

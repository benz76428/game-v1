extends Area2D

var fire_rate: float = 0.4 # Slower than the pistol
var fire_timer: float = 0.0

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if fire_timer > 0:
		fire_timer -= delta

# Called by the player script
func use():
	if fire_timer <= 0:
		const MILK_BULLET = preload("res://Scenes/Weapons/bullet.tscn")
		var new_bullet = MILK_BULLET.instantiate()
		new_bullet.global_position = %ShootingPoint.global_position
		new_bullet.global_rotation = %ShootingPoint.global_rotation
		get_tree().current_scene.add_child(new_bullet)
		fire_timer = fire_rate

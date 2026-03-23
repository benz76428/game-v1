extends BaseWeapon

var fire_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# Always point at the mouse
	look_at(get_global_mouse_position())
	
	# Count down the cooldown
	if fire_timer > 0:
		fire_timer -= delta
		
# --- CHANGED: Renamed use() to shoot(aim_dir) to match BaseWeapon ---
func shoot(aim_dir: Vector2) -> void:
	# ONLY shoot if the cooldown timer is at or below zero
	if fire_timer <= 0:
		const BULLET = preload("res://Scenes/Weapons/pistol/bullet.tscn")
		var new_bullet = BULLET.instantiate()
		
		new_bullet.global_position = %ShootingPoint.global_position 
		new_bullet.global_rotation = %ShootingPoint.global_rotation 
		
		# Add to the main scene tree
		get_tree().current_scene.add_child(new_bullet)
		
		# RESET the timer so you have to wait for the next shot
		# (fire_rate is inherited automatically from BaseWeapon!)
		fire_timer = fire_rate

extends BaseWeapon

func _physics_process(delta: float) -> void:
	# This forces the weapon (and the ShootingPoint) to rotate and aim at the mouse
	look_at(get_global_mouse_position())

func shoot(aim_direction: Vector2) -> void:
	if not can_shoot or projectile_scene == null: 
		return
		
	can_shoot = false
	
	# Instantiate its own UNIQUE projectile
	var drop = projectile_scene.instantiate()
	
	# 1. Spawns exactly at the Marker2D
	drop.global_position = %ShootingPoint.global_position
	
	# 2. Rotates to match the Marker2D's rotation
	drop.global_rotation = %ShootingPoint.global_rotation
	
	get_tree().current_scene.add_child(drop)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

extends BaseWeapon
# Notice we extend BaseWeapon instead of Node2D!

func shoot(aim_direction: Vector2) -> void:
	if not can_shoot or projectile_scene == null: return
	can_shoot = false
	
	# Instantiate its own UNIQUE projectile
	var drop = projectile_scene.instantiate()
	drop.global_position = global_position
	drop.direction = aim_direction
	get_tree().current_scene.add_child(drop)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

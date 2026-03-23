extends CanvasLayer

@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel
@onready var health_bar = $Control/HealthBar 

func _ready() -> void:
	# Wait one frame to guarantee the Player has spawned in
	await get_tree().process_frame
	
	# Find the player and connect to their signals. 
	# NOTE: Your file uses lowercase "player", so make sure the group name is exactly "player"!
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# --- XP & Level Setup ---
		player.xp_changed.connect(_update_xp_bar)
		player.level_changed.connect(_update_level_label)
		
		_update_xp_bar(player.current_xp, player.xp_to_next_level)
		_update_level_label(player.current_level)
		
		# --- Health Setup ---
		player.health_changed.connect(update_health_bar)
		update_health_bar(player.health, player.max_health)
	else:
		print("ERROR: HUD could not find the Player in the 'player' group!")

func _update_xp_bar(current_val, max_val):
	xp_bar.max_value = max_val
	xp_bar.value = current_val

func _update_level_label(new_level):
	level_label.text = "Level: " + str(new_level)
	
func update_health_bar(current_health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = current_health

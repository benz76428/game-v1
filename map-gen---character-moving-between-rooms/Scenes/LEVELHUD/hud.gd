extends CanvasLayer

@onready var xp_bar: ProgressBar = $Control/XPBar
@onready var level_label: Label = $Control/LevelLabel

func _ready() -> void:
	# Find the player and connect to their signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.xp_changed.connect(_update_xp_bar)
		player.level_changed.connect(_update_level_label)
		
		# Initialize the UI with starting values
		_update_xp_bar(player.current_xp, player.xp_to_next_level)
		_update_level_label(player.current_level)

func _update_xp_bar(current_val, max_val):
	xp_bar.max_value = max_val
	xp_bar.value = current_val

func _update_level_label(new_level):
	level_label.text = "Level: " + str(new_level)

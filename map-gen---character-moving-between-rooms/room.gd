extends Node2D
class_name Room

@export_group("Door Configuration")
@export var door_top: bool
@export var door_bot: bool
@export var door_left: bool
@export var door_right: bool

@export_group("Encounter Settings")
@export var wave_duration: float = 20.0 # Total seconds the wave lasts
@export var spawn_interval: float = 1.5 # Seconds between each enemy spawn

@onready var sprite: Sprite2D = $Sprite2D

var alive_enemies: int = 0
var type: int # 1 for Start, 0 for Normal
var is_spawning: bool = false
var wave_timer: Timer
var spawn_timer: Timer
var spawners: Array[Node] = []

func _ready() -> void:
	setup_doors()
	if sprite:
		sprite.modulate = Color.CHARTREUSE if type == 1 else Color.CORNSILK
		
	# Setup the timer that controls the total wave length
	wave_timer = Timer.new()
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_ended)
	add_child(wave_timer)
	
	# Setup the timer that spits out enemies continuously
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func get_door_mask() -> int:
	var mask = 0
	if door_top:    mask += 1
	if door_right:  mask += 2
	if door_bot:    mask += 4
	if door_left:   mask += 8
	return mask

func setup_doors():
	var d_top = get_node_or_null("DoorTop")
	var d_bot = get_node_or_null("DoorBottom")
	var d_left = get_node_or_null("DoorLeft")
	var d_right = get_node_or_null("DoorRight")

	if d_top:
		d_top.visible = door_top
		d_top.set_deferred("monitoring", door_top)
	if d_bot:
		d_bot.visible = door_bot
		d_bot.set_deferred("monitoring", door_bot)
	if d_left:
		d_left.visible = door_left
		d_left.set_deferred("monitoring", door_left)
	if d_right:
		d_right.visible = door_right
		d_right.set_deferred("monitoring", door_right)

func spawn_enemies() -> void:
	spawners = find_children("*", "EnemySpawner", true, false)
	
	# If no spawners or it's a start room, clear immediately
	if spawners.is_empty():
		_mark_room_as_cleared()
		return
		
	is_spawning = true
	wave_timer.start(wave_duration)
	spawn_timer.start(spawn_interval)
	
	# Spawn the first enemy immediately
	_on_spawn_timer_timeout()

func _on_spawn_timer_timeout() -> void:
	if not is_spawning: return
	
	# Pick a random spawner from the room
	var spawner = spawners.pick_random()
	if spawner.has_method("spawn"):
		var enemy = spawner.spawn()
		if enemy != null:
			alive_enemies += 1
			enemy.tree_exited.connect(_on_enemy_died)

func _on_wave_ended() -> void:
	is_spawning = false
	spawn_timer.stop()
	
	# If the player already killed everything on screen when the wave ends
	if alive_enemies <= 0:
		_mark_room_as_cleared()

func _on_enemy_died() -> void:
	if not is_inside_tree(): 
		return
		
	alive_enemies -= 1
	
	# Only clear the room if the wave timer is completely finished AND all enemies are dead
	if alive_enemies <= 0 and not is_spawning:
		_mark_room_as_cleared()

func _mark_room_as_cleared() -> void:
	var generator = get_tree().current_scene
	if generator and generator.has_method("mark_current_room_cleared"):
		generator.mark_current_room_cleared()
	else:
		for child in get_tree().root.get_children():
			if child.has_method("mark_current_room_cleared"):
				child.mark_current_room_cleared()
				break

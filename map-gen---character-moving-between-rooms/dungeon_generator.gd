extends Node2D

enum Side {LEFT, TOP, RIGHT, BOTTOM}

# --- Configuration ---
@export_group("World Settings")
@export var world_size: Vector2i = Vector2i(4, 4)
@export var number_of_rooms: int = 20

@export_group("Library Settings")
@export_dir var rooms_folder_path: String = "res://rooms/"
@export var room_library: Array[PackedScene] = []

@export_group("Minimap Settings")
@export var dot_size: int = 6
@export var dot_sep: int = 2

@export_group("References")
@export var player: CharacterBody2D

# --- Internal State ---
@onready var minimap_container = $CanvasLayer/Minimap/MapBackground
@onready var map_root = %MapRoot
@onready var room_info_label = $CanvasLayer/RoomInfoLabel

var rooms: Array = []
var taken_positions: Array[Vector2i] = []
var grid_size_x: int
var grid_size_y: int
var current_coords: Vector2i = Vector2i.ZERO
var active_room_instance: Node2D = null
var is_transitioning: bool = false

# --- Lifecycle ---

func _ready() -> void:
	grid_size_x = world_size.x
	grid_size_y = world_size.y
	
	load_room_library()
	create_rooms()
	set_room_doors()
	
	current_coords = Vector2i(grid_size_x, grid_size_y)
	load_current_room()
	update_minimap()
	is_transitioning = false

# --- Room Logic ---

func load_current_room(entry_side = null) -> bool:
	if not rooms_array_check(current_coords): 
		return false
		
	var room_data = rooms[current_coords.x][current_coords.y]

	# 1. Generate Mask
	var req_mask: int = 0
	if room_data["door_top"]:    req_mask += 1
	if room_data["door_right"]:  req_mask += 2
	if room_data["door_bot"]:    req_mask += 4
	if room_data["door_left"]:   req_mask += 8
	
	# 2. Find Compatible Scene
	var compatible_scenes: Array[PackedScene] = []
	for scene in room_library:
		var temp = scene.instantiate()
		if temp.has_method("get_door_mask") and temp.get_door_mask() == req_mask:
			compatible_scenes.append(scene)
		temp.queue_free()
		
	if compatible_scenes.is_empty():
		is_transitioning = false
		return false

	# 3. Swap Rooms
	if active_room_instance:
		active_room_instance.queue_free()
		
	active_room_instance = compatible_scenes.pick_random().instantiate()
	active_room_instance.door_top = room_data["door_top"]
	active_room_instance.door_bot = room_data["door_bot"]
	active_room_instance.door_left = room_data["door_left"]
	active_room_instance.door_right = room_data["door_right"]
	
	map_root.add_child(active_room_instance)
	
	if active_room_instance.has_method("setup_doors"):
		active_room_instance.setup_doors()

	# 4. Physics Sync & Teleport
	await get_tree().physics_frame

	if entry_side != null:
		place_player_at_door(entry_side)
	
	# 5. Connect Doors
	var found_doors = active_room_instance.find_children("*", "Area2D", true, false)
	for d in found_doors:
		if d.has_signal("player_entered"):
			# Clean up existing connections before reconnecting
			if d.is_connected("player_entered", _on_door_entered):
				d.disconnect("player_entered", _on_door_entered)
			d.connect("player_entered", _on_door_entered)
			
	if room_data.get("has_spawned", false) == false:
		if active_room_instance.has_method("spawn_enemies"):
			active_room_instance.spawn_enemies()
			
	is_transitioning = false
	return true
# --- Navigation ---

func _on_door_entered(side: int) -> void:
	if is_transitioning: 
		return
	
	is_transitioning = true
	if player:
		player.velocity = Vector2.ZERO
	
	var old_coords = current_coords
	match side:
		Side.LEFT:   current_coords.x -= 1
		Side.TOP:    current_coords.y -= 1
		Side.RIGHT:  current_coords.x += 1
		Side.BOTTOM: current_coords.y += 1
		
	if not rooms_array_check(current_coords):
		current_coords = old_coords
		is_transitioning = false
		return

	var arrival_side = get_opposite_side(side)
	call_deferred("load_current_room", arrival_side)
	update_minimap()

func place_player_at_door(arrival_side: int) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		return
	
	var mid_x: int = 432 
	var mid_y: int = 239
	var target_pos: Vector2 = Vector2.ZERO
	
	match arrival_side:
		Side.LEFT:   target_pos = Vector2(80, mid_y)
		Side.TOP:    target_pos = Vector2(mid_x, 80)
		Side.RIGHT:  target_pos = Vector2(784, mid_y)
		Side.BOTTOM: target_pos = Vector2(mid_x, 398)

	player.velocity = Vector2.ZERO
	player.global_position = target_pos
	
	if player.has_method("reset_physics_interpolation"):
		player.reset_physics_interpolation()

func get_opposite_side(side: int) -> int:
	match side:
		Side.LEFT:   return Side.RIGHT
		Side.TOP:    return Side.BOTTOM
		Side.RIGHT:  return Side.LEFT
		Side.BOTTOM: return Side.TOP
	return Side.LEFT

# --- Generation Logic ---

func create_rooms() -> void:
	rooms = []
	taken_positions = []
	
	# Initialize Grid
	for i in range(grid_size_x * 2):
		var row = []
		for j in range(grid_size_y * 2): 
			row.append(null)
		rooms.append(row)
		
	# Place Start
	var start_pos = Vector2i.ZERO
	rooms[grid_size_x][grid_size_y] = {"grid_pos": start_pos, "type": 1, "has_spawned": true}
	taken_positions.append(start_pos)
	
	# Generate neighbors
	for i in range(number_of_rooms - 1):
		var check_pos = new_position()
		rooms[check_pos.x + grid_size_x][check_pos.y + grid_size_y] = {
			"grid_pos": check_pos, 
			"type": 0,
			"has_spawned": false
		}
		taken_positions.append(check_pos)

func new_position() -> Vector2i:
	var checking_pos: Vector2i = Vector2i.ZERO
	var is_valid: bool = false
	
	while not is_valid:
		var base_pos: Vector2i
		# 70% Snaking / 30% Random Branching
		if randf() < 0.7 and not taken_positions.is_empty():
			base_pos = taken_positions.back()
		else:
			base_pos = taken_positions.pick_random()
		
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		directions.shuffle()
		
		for dir in directions:
			var target = base_pos + dir
			if taken_positions.has(target): continue
			if abs(target.x) >= grid_size_x or abs(target.y) >= grid_size_y: continue
				
			if count_neighbors(target) <= 1:
				checking_pos = target
				is_valid = true
				break
	return checking_pos

func count_neighbors(pos: Vector2i) -> int:
	var count: int = 0
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for dir in directions:
		if taken_positions.has(pos + dir):
			count += 1
	return count

func set_room_doors() -> void:
	var max_x = grid_size_x * 2
	var max_y = grid_size_y * 2
	for x in range(max_x):
		for y in range(max_y):
			if rooms[x][y] == null: continue
			var room = rooms[x][y]
			room["door_top"]   = (y - 1 >= 0) and rooms[x][y - 1] != null
			room["door_bot"]   = (y + 1 < max_y) and rooms[x][y + 1] != null
			room["door_left"]  = (x - 1 >= 0) and rooms[x - 1][y] != null
			room["door_right"] = (x + 1 < max_x) and rooms[x + 1][y] != null

# --- Utilities ---

func load_room_library() -> void:
	room_library.clear()
	var dir = DirAccess.open(rooms_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn") or file_name.ends_with(".remap"):
				var actual_name = file_name.replace(".remap", "")
				var path = rooms_folder_path.path_join(actual_name)
				var scene = load(path)
				if scene: room_library.append(scene)
			file_name = dir.get_next()
		dir.list_dir_end()

func update_minimap() -> void:
	if !minimap_container: return
	for child in minimap_container.get_children(): 
		child.queue_free()
		
	for x in range(grid_size_x * 2):
		for y in range(grid_size_y * 2):
			if rooms[x][y] == null: continue
			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(dot_size, dot_size)
			dot.position = Vector2(x, y) * (dot_size + dot_sep)
			
			if Vector2i(x, y) == current_coords:
				dot.color = Color.WHITE
			elif rooms[x][y]["type"] == 1:
				dot.color = Color.GREEN
			else:
				dot.color = Color.GRAY
				
			minimap_container.add_child(dot)

func rooms_array_check(coords: Vector2i) -> bool:
	if coords.x < 0 or coords.x >= rooms.size(): return false
	if coords.y < 0 or coords.y >= rooms[0].size(): return false
	return rooms[coords.x][coords.y] != null
	
func mark_current_room_cleared() -> void:
	if rooms[current_coords.x][current_coords.y] != null:
		rooms[current_coords.x][current_coords.y]["has_spawned"] = true

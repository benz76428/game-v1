class_name Player
extends CharacterBody2D

signal xp_changed(current_xp, max_xp)
signal level_changed(new_level)

const MUTATION_PICKER_SCENE = preload("res://Scenes/picker/mutation_picker.tscn")

# ==========================================
# STATS & MOVEMENT VARIABLES
# ==========================================
var player_direction: Vector2 = Vector2.DOWN

# Dash Variables
var is_dashing: bool = false
var dash_speed: float = 800.0   
var dash_duration: float = 0.2 
var dash_timer: float = 0.0

# XP Variables
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 5

# ==========================================
# MUTATION & WEAPON INVENTORY
# ==========================================
# Keeps track of all passive and modifier DNA the player has
var active_mutations: Array[Mutation] = []

# Keeps track of up to 4 active weapons
var weapons: Array[BaseWeapon] = []
const MAX_WEAPONS = 4

# Old dictionary - kept here so your Fart Dash doesn't break while we transition!
var mutations = {
	"milk_nipples": {"active": false, "level": 0},
	"fart_dash": {"active": false, "level": 0}
}


# ==========================================
# CORE LIFECYCLE (Ready & Process)
# ==========================================
func _ready() -> void:
	# When the game starts, look for the starting Gun and equip it automatically!
	var starting_gun = get_node_or_null("Gun")
	if starting_gun and starting_gun is BaseWeapon:
		add_weapon(starting_gun)

func _physics_process(delta: float) -> void:
	update_aim_direction()
	handle_inputs(delta)
	move_and_slide()


# ==========================================
# INPUT HANDLING (Dash, Move, Shoot)
# ==========================================
func handle_inputs(delta: float) -> void:
	# --- 1. HANDLE DASH STATE ---
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# Reset velocity when dash ends
			velocity = Vector2.ZERO 
		return # Stop reading inputs while we are dashing

	# --- 2. HANDLE DASH INPUT ---
	if Input.is_action_just_pressed("ui_accept"): # Usually "Space"
		is_dashing = true
		dash_timer = dash_duration
		
		# Figure out which way we are moving to dash in that direction
		var move_dir = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		
		# Fallback to mouse only if no keys are held
		if move_dir == Vector2.ZERO:
			move_dir = (get_global_mouse_position() - global_position).normalized()
		
		velocity = move_dir * dash_speed
		
		# Check our old mutation tracker for the fart
		if mutations["fart_dash"]["active"]:
			spawn_fart_cloud()
		return # Skip the rest of the inputs this frame

	# --- 3. HANDLE NORMAL MOVEMENT ---
	var move_dir = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	# Assuming you have a normal speed variable, default to 200 if you don't!
	var speed = 200.0 
	if "speed" in self: speed = self.speed 
	velocity = move_dir * speed

	# --- 4. HANDLE WEAPON FIRING ---
	var aim_dir = (get_global_mouse_position() - global_position).normalized()

	# Slot 0: Left Mouse Button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and weapons.size() > 0:
		weapons[0].shoot(aim_dir)

	# Slot 1: Right Mouse Button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and weapons.size() > 1:
		weapons[1].shoot(aim_dir)

	# Slot 2: 'Q' Key
	if Input.is_physical_key_pressed(KEY_Q) and weapons.size() > 2:
		weapons[2].shoot(aim_dir)

	# Slot 3: 'E' Key
	if Input.is_physical_key_pressed(KEY_E) and weapons.size() > 3:
		weapons[3].shoot(aim_dir)


# ==========================================
# WEAPON & MUTATION MANAGEMENT
# ==========================================
func add_weapon(new_weapon: BaseWeapon) -> void:
	# Finds the next available slot and assigns the weapon to it
	if weapons.size() < MAX_WEAPONS:
		weapons.append(new_weapon)
		print("Equipped new weapon in slot: ", weapons.size() - 1)
	else:
		print("Weapon slots are full! Cannot equip.")
		new_weapon.queue_free() # Destroy the weapon if we have no room for it

func inject_dna(new_mutation: Mutation) -> void:
	# Called by the mutation picker when the player selects an upgrade
	active_mutations.append(new_mutation)
	new_mutation.apply_mutation(self)


# ==========================================
# LEVELING & XP
# ==========================================
func gain_xp(amount: int) -> void:
	current_xp += amount
	xp_changed.emit(current_xp, xp_to_next_level)
	if current_xp >= xp_to_next_level:
		level_up()

func level_up():
	current_level += 1
	current_xp = 0
	xp_to_next_level += 5
	
	level_changed.emit(current_level)
	xp_changed.emit(current_xp, xp_to_next_level)
	
	# Open the UI Menu
	var picker_instance = MUTATION_PICKER_SCENE.instantiate()
	get_tree().current_scene.add_child(picker_instance)
	
	# Pause the game and generate choices
	get_tree().paused = true
	picker_instance.generate_choices()


# ==========================================
# UTILITY FUNCTIONS
# ==========================================
func update_aim_direction() -> void:
	var mouse_pos = get_global_mouse_position()
	var look_vec = (mouse_pos - global_position).normalized()
	
	if abs(look_vec.x) > abs(look_vec.y):
		player_direction = Vector2.RIGHT if look_vec.x > 0 else Vector2.LEFT
	else:
		player_direction = Vector2.DOWN if look_vec.y > 0 else Vector2.UP

func spawn_fart_cloud() -> void:
	print("Dashing with FART cloud!")

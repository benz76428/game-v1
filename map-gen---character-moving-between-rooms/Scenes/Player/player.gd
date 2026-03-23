class_name Player
extends CharacterBody2D

signal xp_changed(current_xp, max_xp)
signal level_changed(new_level)
signal health_changed(current_health, max_health) # Added a signal for your HUD!

const MUTATION_PICKER_SCENE = preload("res://Scenes/picker/mutation_picker.tscn")

var max_health: int = 100
var health: int = max_health
# ==========================================
# BASE STATS (The raw, naked player stats)
# ==========================================
@export var base_max_health: float = 100.0
@export var base_speed: float = 200.0
@export var base_dash_speed: float = 800.0
@export var base_dash_duration: float = 0.2
@export var base_fire_rate_mult: float = 1.0
@export var base_damage_mult: float = 1.0

# ==========================================
# CURRENT STATS (Base stats + Mutation modifiers)
# ==========================================
var current_max_health: float
var current_health: float

var current_speed: float
var current_dash_speed: float
var current_dash_duration: float

var current_fire_rate_mult: float
var current_damage_mult: float

# ==========================================
# STATE VARIABLES
# ==========================================
var player_direction: Vector2 = Vector2.DOWN
var is_dashing: bool = false
var dash_timer: float = 0.0

var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 5

# ==========================================
# INVENTORY
# ==========================================
var active_mutations: Array[Mutation] = []
var weapons: Array[BaseWeapon] = []
const MAX_WEAPONS = 4

var mutations = {
	"milk_nipples": {"active": false, "level": 0},
	"fart_dash": {"active": false, "level": 0}
}


# ==========================================
# CORE LIFECYCLE
# ==========================================
func _ready() -> void:
	# Initialize stats when the game starts
	recalculate_stats()
	current_health = current_max_health 
	
	var starting_gun = get_node_or_null("Gun")
	if starting_gun and starting_gun is BaseWeapon:
		add_weapon(starting_gun)

func _physics_process(delta: float) -> void:
	update_aim_direction()
	handle_inputs(delta)
	move_and_slide()


# ==========================================
# STAT MANAGEMENT
# ==========================================
func recalculate_stats() -> void:
	# 1. Reset everything back to the raw base values
	current_max_health = base_max_health
	current_speed = base_speed
	current_dash_speed = base_dash_speed
	current_dash_duration = base_dash_duration
	current_fire_rate_mult = base_fire_rate_mult
	current_damage_mult = base_damage_mult
	
	# 2. Loop through all active mutations and add their bonuses
	for mutation in active_mutations:
		# We will add this function to your mutations later!
		if mutation.has_method("apply_stat_modifiers"):
			mutation.apply_stat_modifiers(self)
			
	# 3. Ensure we don't accidentally have more health than our max after recalculating
	current_health = clamp(current_health, 0, current_max_health)
	health_changed.emit(current_health, current_max_health)

func take_damage(amount: int) -> void:
	# Subtract the damage from the player's health
	current_health -= amount
	
	# Emit the signal so your HUD updates!
	health_changed.emit(current_health, current_max_health)
	
	print("Player took ", amount, " damage! Health is now: ", current_health)
	
	if current_health <= 0:
		print("Player died!")
		# We can add game over logic here later

# If you have healing items/mutations, do the same:
func heal(amount: int):
	health += amount
	if health > max_health:
		health = max_health
	
	health_changed.emit(health, max_health)

func die() -> void:
	print("Player has died!")
	# Restart scene, show game over screen, etc.


# ==========================================
# INPUT HANDLING
# ==========================================
func handle_inputs(delta: float) -> void:
	# --- 1. HANDLE DASH STATE ---
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO 
		return 

	# --- 2. HANDLE DASH INPUT ---
	if Input.is_action_just_pressed("ui_accept"):
		is_dashing = true
		dash_timer = current_dash_duration # <--- Now uses CURRENT stat
		
		var move_dir = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		if move_dir == Vector2.ZERO:
			move_dir = (get_global_mouse_position() - global_position).normalized()
		
		velocity = move_dir * current_dash_speed # <--- Now uses CURRENT stat
		
		if mutations["fart_dash"]["active"]:
			spawn_fart_cloud()
		return

	# --- 3. HANDLE NORMAL MOVEMENT ---
	var move_dir = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = move_dir * current_speed # <--- Now uses CURRENT stat

	# --- 4. HANDLE WEAPON FIRING ---
	var aim_dir = (get_global_mouse_position() - global_position).normalized()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and weapons.size() > 0:
		weapons[0].shoot(aim_dir)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and weapons.size() > 1:
		weapons[1].shoot(aim_dir)
	if Input.is_physical_key_pressed(KEY_Q) and weapons.size() > 2:
		weapons[2].shoot(aim_dir)
	if Input.is_physical_key_pressed(KEY_E) and weapons.size() > 3:
		weapons[3].shoot(aim_dir)


# ==========================================
# INVENTORY & XP
# ==========================================
func inject_dna(new_mutation: Mutation) -> void:
	active_mutations.append(new_mutation)
	new_mutation.apply_mutation(self)
	
	# Recalculate stats every time we get a new mutation!
	recalculate_stats()

func add_weapon(new_weapon: BaseWeapon) -> void:
	if weapons.size() < MAX_WEAPONS:
		weapons.append(new_weapon)
		print("Equipped new weapon in slot: ", weapons.size() - 1)
	else:
		new_weapon.queue_free()

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
	
	var picker_instance = MUTATION_PICKER_SCENE.instantiate()
	get_tree().current_scene.add_child(picker_instance)
	get_tree().paused = true
	picker_instance.generate_choices()


# ==========================================
# UTILITY
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

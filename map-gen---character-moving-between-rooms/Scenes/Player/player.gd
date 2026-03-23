class_name Player
extends CharacterBody2D

signal xp_changed(current_xp, max_xp)
signal level_changed(new_level)

const MUTATION_PICKER_SCENE = preload("res://Scenes/picker/mutation_picker.tscn")

# --- Stats & Direction ---
var player_direction: Vector2 = Vector2.DOWN
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 5

# --- Dash Variables (Speeds Restored) ---
var is_dashing: bool = false
var dash_speed: float = 800.0   # Put back to fast speed
var dash_duration: float = 0.2 # Put back to original duration
var dash_timer: float = 0.0

# --- Mutation Tracker ---
var mutations = {
	"milk_nipples": {"active": false, "level": 0},
	"fart_dash": {"active": false, "level": 0}
}
var active_mutations: Array[Mutation] = []
# --- Weapon Slot References ---
@onready var slot_lmb = $Gun
@onready var slot_rmb = get_node_or_null("MilkNipples")

func _physics_process(delta: float) -> void:
	update_aim_direction()
	handle_inputs(delta)
	move_and_slide()

func handle_inputs(delta: float) -> void:
	# 1. Handle Dash State
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# We don't force velocity to zero here so the Walk state can take over smoothly
	
	# 2. Trigger Dash
	if Input.is_action_just_pressed("dash") and not is_dashing:
		start_dash()

	# 3. Handle Weapon Slots (Using your new primary/secondary fire names)
	if Input.is_action_pressed("primary_fire") and slot_lmb:
		slot_lmb.use()
	
	if mutations["milk_nipples"]["active"] and Input.is_action_pressed("secondary_fire"):
		if slot_rmb:
			slot_rmb.use()

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	
	# FIX: Use "walk_" prefix to match your Input Map/Walk State
	var move_dir = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	
	# Fallback to mouse only if no keys are held
	if move_dir == Vector2.ZERO:
		move_dir = (get_global_mouse_position() - global_position).normalized()
	
	velocity = move_dir * dash_speed
	
	if mutations["fart_dash"]["active"]:
		spawn_fart_cloud()

func spawn_fart_cloud() -> void:
	print("Dashing with FART cloud!")

func update_aim_direction() -> void:
	var mouse_pos = get_global_mouse_position()
	var look_vec = (mouse_pos - global_position).normalized()
	
	if abs(look_vec.x) > abs(look_vec.y):
		player_direction = Vector2.RIGHT if look_vec.x > 0 else Vector2.LEFT
	else:
		player_direction = Vector2.DOWN if look_vec.y > 0 else Vector2.UP
# --- XP and Leveling Logic ---
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
	
	# --- THE NEW MUTATION MENU LOGIC ---
	var picker_instance = MUTATION_PICKER_SCENE.instantiate()
	
	# Add the UI to the current scene tree
	get_tree().current_scene.add_child(picker_instance)
	
	# Pause the game so enemies stop moving while you choose!
	get_tree().paused = true
	
	# Call the NEW function we created in mutation_picker.gd
	picker_instance.generate_choices()

func _on_mutation_chosen(m_name: String):
	mutations[m_name]["active"] = true
	mutations[m_name]["level"] += 1
	
	if m_name == "milk_nipples" and slot_rmb:
		slot_rmb.visible = true
	
	print("Mutation Level Up: ", m_name, " is now Level ", mutations[m_name]["level"])
func inject_dna(new_mutation: Mutation) -> void:
	active_mutations.append(new_mutation)
	
	# The magic happens here: the mutation modifies the player itself!
	new_mutation.apply_mutation(self)
	
	# Optional: Play a sound, flash the screen green, etc.

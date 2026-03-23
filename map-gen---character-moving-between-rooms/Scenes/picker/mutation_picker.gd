extends CanvasLayer

signal mutation_selected(mutation_name)

@onready var container: HBoxContainer = %HBoxContainer 

# This is where you dragged your .tres files in the Inspector
@export var possible_mutations: Array[Mutation]

func generate_choices() -> void:
	# SAFETY: Wait for the UI to be fully loaded before adding buttons
	if not is_inside_tree(): await ready
	
	# 1. Clear out any old buttons if they exist
	for child in container.get_children():
		child.queue_free()
		
	# 2. Check if we have mutations
	if possible_mutations.is_empty():
		print("ERROR: No mutations assigned in the inspector!")
		return
		
	# 3. Duplicate and shuffle the array so we get random choices
	var available = possible_mutations.duplicate()
	available.shuffle()
	
	# Pick up to 3 choices
	var num_choices = min(3, available.size())
	
	# 4. Create the buttons dynamically!
	for i in range(num_choices):
		var mutation_data = available[i]
		var btn = Button.new()
		
		# Set the text and size
		btn.text = mutation_data.mutation_name + "\n\n" + mutation_data.description
		btn.custom_minimum_size = Vector2(200, 300)
		
		# Connect the button click to our function, passing the specific mutation
		btn.pressed.connect(_on_button_pressed.bind(mutation_data))
		
		# Add the button to your UI container
		container.add_child(btn)

func _on_button_pressed(mutation_data: Mutation) -> void:
	# Find the player in the scene
	var player = get_tree().get_first_node_in_group("player") 
	if player:
		# Give the player the new DNA
		player.inject_dna(mutation_data)
		
	# Unpause the game and destroy the menu
	get_tree().paused = false
	queue_free()

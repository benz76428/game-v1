extends CanvasLayer

signal mutation_selected(mutation_name)

# Change the $ to a % here:
@onready var container: HBoxContainer = %HBoxContainer 
@export var possible_mutations: Array[Mutation]
func generate_choices() -> void:
	# Make sure we have mutations to pick from!
	if possible_mutations.is_empty():
		print("ERROR: No mutations assigned in the inspector!")
		return
		
	# Shuffle the array to get random mutations
	possible_mutations.shuffle()
	
	# Pick the first 3 (or fewer if you don't have 3 yet)
	var num_choices = min(3, possible_mutations.size())
	
	for i in range(num_choices):
		var mutation_data = possible_mutations[i]
		
		# Assuming you have UI buttons or panels set up
		var button = get_node("Button" + str(i + 1)) 
		button.text = mutation_data.mutation_name
		# If you have descriptions/icons:
		# button.get_node("Description").text = mutation_data.description
		# button.get_node("Icon").texture = mutation_data.icon
		
# Inside mutation_picker.gd, when a button is pressed:
func _on_button_pressed(mutation_data: Mutation) -> void:
	# Get your player (you might emit a signal here, or call the player directly)
	var player = get_tree().get_first_node_in_group("player") 
	if player:
		player.inject_dna(mutation_data)
		
	# Close the UI and unpause
	queue_free()

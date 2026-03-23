extends CanvasLayer

signal mutation_selected(mutation_name)

# Change the $ to a % here:
@onready var container: HBoxContainer = %HBoxContainer 

var mutation_data = {
	"fart_dash": {
		"title": "Fart Dash",
		"description": "Press 'Space' to dash. Leaves A Fart Cloud that poisens enemies within it"
	},
	"milk_nipples": {
		"title": "Milk Nipples",
		"description": "shoot milk from yo titties"
	}
}

func setup_options(available_mutations: Array):
	# SAFETY: If the node isn't ready yet, wait a frame
	if not is_inside_tree(): await ready
	
	for child in container.get_children():
		child.queue_free()
	
	for m_name in available_mutations:
		var btn = Button.new()
		var data = mutation_data[m_name]
		
		btn.text = data["title"] + "\n\n" + data["description"]
		btn.custom_minimum_size = Vector2(200, 300)
		
		btn.pressed.connect(_on_option_selected.bind(m_name))
		container.add_child(btn)

func _on_option_selected(m_name: String):
	mutation_selected.emit(m_name)
	get_tree().paused = false
	queue_free()

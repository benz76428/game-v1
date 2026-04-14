extends Area2D
class_name Door


signal player_entered(side)

enum Side {LEFT, TOP, RIGHT, BOTTOM}
@export var side: Side

func _ready():
	
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):

	
	if body.is_in_group("player") or body.name == "Player":
		player_entered.emit(side)

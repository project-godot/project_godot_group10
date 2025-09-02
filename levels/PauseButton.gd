extends Button

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("button"):
		button.mouse_exited.connect(mouse_interaction.bind(button, "exited"))
		button.mouse_entered.connect(mouse_interaction.bind(button, "entered"))

# função de abrir a pop up de Pause Menu
func _on_pressed():
	get_tree().change_scene_to_file("res://levels/PauseMenu.tscn")
	

# função de interação do mouse
func mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

extends Button

@export var scene_path: String

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("button"):
		button.mouse_exited.connect(mouse_interaction.bind(button, "exited"))
		button.mouse_entered.connect(mouse_interaction.bind(button, "entered"))
	
func _on_pressed():
	if not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Caminho da cena não definido no Inspector do botão!")

func mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

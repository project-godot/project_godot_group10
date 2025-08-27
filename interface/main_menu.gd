extends Control

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("button"):
		button.pressed.connect(on_button_pressed.bind(button))
		button.mouse_exited.connect(mouse_interaction.bind(button, "exited"))
		button.mouse_entered.connect(mouse_interaction.bind(button, "entered"))

func on_button_pressed(button: Button) -> void:
	match button.name:
		"ButtonPlay":
			get_tree().change_scene_to_file("res://cenas/controls.tscn")
			
		"ButtonControls":
			get_tree().change_scene_to_file("res://cenas/controls.tscn")
			
		"ButtonQuit":
			get_tree().quit()
			
		"ButtonInfo":
			OS.shell_open("https://seu_link_aqui.com")

func mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

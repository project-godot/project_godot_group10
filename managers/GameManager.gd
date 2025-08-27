extends Control

func _ready() -> void:
	for button in get_tree().get_nodes_in_group("button"):
		button.pressed.connect(on_button_pressed.bind(button))
		button.mouse_exited.connect(mouse_interaction.bind(button, "exited"))
		button.mouse_entered.connect(mouse_interaction.bind(button, "entered"))

func on_button_pressed(button: Button) -> void:
	match button.name:
		"ButtonPlay":
			get_tree().change_scene_to_file("")
			
		"ButtonControls":
			get_tree().change_scene_to_file("res://main/Controls.tscn")
			
		"ButtonQuit":
			get_tree().quit()
			
		"ButtonInfo":
			OS.shell_open("https://media.licdn.com/dms/image/v2/C4E12AQGC77I_ni5vhQ/article-cover_image-shrink_600_2000/article-cover_image-shrink_600_2000/0/1547650472214?e=2147483647&v=beta&t=0IqtSeF59nVecE6-YVnVH1Pp2hw207O-eilh6pQaAMA")

func mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 1.0
		"entered":
			button.modulate.a = 0.5

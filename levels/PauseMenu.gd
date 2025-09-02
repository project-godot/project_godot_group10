extends CanvasLayer

# função de interação do mouse
func mouse_interaction(button: Button, state: String) -> void:
	match state:
		"exited":
			button.modulate.a = 0.5
		"entered":
			button.modulate.a = 1.0

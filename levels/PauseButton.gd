extends CanvasLayer

@onready var button = $Button

func _ready() -> void:
	button.mouse_exited.connect(_on_mouse_exited)
	button.mouse_entered.connect(_on_mouse_entered)
	button.pressed.connect(_on_pressed)

# função abrir o menu de pause
func _on_pressed():
	get_tree().paused = true
	var pause_menu = preload("res://levels/PauseMenu.tscn").instantiate()
	get_tree().current_scene.add_child(pause_menu)

# função de interação do mouse
func _on_mouse_exited():
	button.modulate.a = 1.0

func _on_mouse_entered():
	button.modulate.a = 0.5

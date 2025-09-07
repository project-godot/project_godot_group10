extends Button

@export var scene_path: String

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_pressed():
	if not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)

# função de interação do mouse
func _on_mouse_exited():
	modulate.a = 1.0

func _on_mouse_entered():
	modulate.a = 0.5

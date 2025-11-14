extends CanvasLayer

@onready var menu_button = $Panel/VBoxContainer/MenuButton

func _ready():
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Pausar o jogo
	get_tree().paused = true

func _on_menu_pressed():
	# Despausar
	get_tree().paused = false
	
	# Voltar para o menu de seleção de níveis
	get_tree().change_scene_to_file("res://main/LevelSelect.tscn")
	
	# Remover o popup
	queue_free()


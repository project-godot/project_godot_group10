extends CanvasLayer

@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Pausar o jogo
	get_tree().paused = true

func _on_restart_pressed():
	# Despausar
	get_tree().paused = false
	
	# Resetar vida do player
	GameManager.player_health = 5
	
	# Recarregar a cena atual
	var current_scene = get_tree().current_scene.scene_file_path
	get_tree().reload_current_scene()
	
	# Remover o popup
	queue_free()

func _on_menu_pressed():
	# Despausar
	get_tree().paused = false
	
	# Voltar para o menu de seleção de níveis
	get_tree().change_scene_to_file("res://main/LevelSelect.tscn")
	
	# Remover o popup
	queue_free()

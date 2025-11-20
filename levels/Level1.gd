extends Node2D

@onready var health_display_scene = preload("res://levels/HealthDisplay.tscn")
@onready var dialogue_box_scene = preload("res://levels/DialogueBox.tscn")

func _ready():
	# Resetar moedas ao entrar na fase
	GameManager.coins_collected = 0
	# Notificar que as moedas foram resetadas (para atualizar o ScoreDisplay)
	GameManager.coin_collected.emit(0)
	
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)
	
	# Adicionar HealthDisplay
	var health_display = health_display_scene.instantiate()
	add_child(health_display)
	
	# Configurar spawn do player
	call_deferred("_setup_player_spawn")
	
	# Mostrar diálogo de boas-vindas
	call_deferred("_show_welcome_dialogue")

func _setup_player_spawn():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Definir spawn inicial como a posição atual do player
		player.set_spawn_position(player.global_position)

func _show_welcome_dialogue():
	var dialogue_box = dialogue_box_scene.instantiate()
	add_child(dialogue_box)
	# Usar o novo sistema DLS
	dialogue_box.show_dls_file("res://dialogues/level1_intro.dls", {
		"nivel": 1,
		"vidas": GameManager.player_health if GameManager.player_health > 0 else 3
	})

func _on_level_completed():
	print("Parabéns! Você coletou todas as moedas!")
	ManagerLevel.unlock_next_level()

func _on_game_over():
	print("Game Over! Você morreu!")
	# Mostrar popup de Game Over
	var game_over_menu = preload("res://levels/GameOverMenu.tscn").instantiate()
	get_tree().current_scene.add_child(game_over_menu)

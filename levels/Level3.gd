extends Node2D

@onready var health_display_scene = preload("res://levels/HealthDisplay.tscn")

var all_enemies_defeated = false

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
	
	# Verificar se todos os inimigos foram derrotados periodicamente
	call_deferred("_start_enemy_check")

func _setup_player_spawn():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Definir spawn inicial como a posição atual do player
		player.set_spawn_position(player.global_position)

func _on_level_completed():
	print("Parabéns! Você coletou todas as moedas!")
	ManagerLevel.unlock_next_level()

func _on_game_over():
	print("Game Over! Você morreu!")
	# Mostrar popup de Game Over
	var game_over_menu = preload("res://levels/GameOverMenu.tscn").instantiate()
	get_tree().current_scene.add_child(game_over_menu)

func _start_enemy_check():
	# Verificar periodicamente se todos os inimigos foram derrotados
	_check_all_enemies_defeated()
	await get_tree().create_timer(0.5).timeout
	_start_enemy_check()

func _check_all_enemies_defeated():
	# Se já mostrou o game over, não verificar novamente
	if all_enemies_defeated:
		return
	
	# Verificar se estamos no level 3
	var current_scene = get_tree().current_scene.scene_file_path
	if not "level3" in current_scene.to_lower():
		return
	
	# Obter todos os inimigos no grupo "enemies"
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Verificar se há inimigos
	if enemies.size() == 0:
		# Todos os inimigos foram derrotados - mostrar mensagem de vitória
		all_enemies_defeated = true
		print("Todos os inimigos do Level 3 foram derrotados!")
		var victory_menu = preload("res://levels/VictoryMenu.tscn").instantiate()
		get_tree().current_scene.add_child(victory_menu)

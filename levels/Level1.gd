extends Node2D

func _ready():
	
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

func _on_level_completed():
	print("Parabéns! Você coletou todas as moedas!")
	ManagerLevel.unlock_next_level()

func _on_game_over():
	print("Game Over! Você morreu!")

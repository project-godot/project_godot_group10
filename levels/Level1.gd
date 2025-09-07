extends Node2D

func _ready():
	var coin_count = get_node("coins").get_child_count()
	GameManager.set_total_coins(coin_count)
	
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)
	
	print("Nível 1 carregado! Total de moedas: ", coin_count)

func _on_level_completed():
	print("Parabéns! Você coletou todas as moedas!")
	ManagerLevel.unlock_next_level()

func _on_game_over():
	print("Game Over! Você morreu!")

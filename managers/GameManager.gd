extends Node

var coins_collected: int = 0
var total_coins: int = 0
var player_health: float = 10.0  # 5 full hearts (each heart = 2 health points)
var current_level: int = 1

signal coin_collected(amount: int)
signal player_health_changed(new_health: float)
signal level_completed
signal game_over

func collect_coin(amount: int = 1):
	coins_collected += amount
	coin_collected.emit(amount)

func set_total_coins(amount: int):
	total_coins = amount

func change_player_health(amount: float):
	player_health += amount
	player_health = max(0.0, player_health) 
	player_health_changed.emit(player_health)
	
	if player_health <= 0:
		game_over.emit()

func next_level():
	current_level += 1

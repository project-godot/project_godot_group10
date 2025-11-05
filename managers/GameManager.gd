extends Node

var coins_collected: int = 0
var total_coins: int = 0
var player_health: int = 5
var current_level: int = 1

signal coin_collected(amount: int)
signal player_health_changed(new_health: int)
signal level_completed
signal game_over

func collect_coin(amount: int = 1):
	coins_collected += amount
	coin_collected.emit(amount)

func set_total_coins(amount: int):
	total_coins = amount

func change_player_health(amount: int):
	player_health += amount
	player_health = max(0, player_health) 
	player_health_changed.emit(player_health)
	
	if player_health <= 0:
		game_over.emit()

func next_level():
	current_level += 1

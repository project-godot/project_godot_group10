extends Node

var coins_collected: int = 0
var total_coins: int = 0
var player_health: float = 10.0  # 5 full hearts (each heart = 2 health points)
var current_level: int = 1

# Player unlock states
var player2_unlocked: bool = false

const SAVE_FILE_PATH = "user://savegame.save"

signal coin_collected(amount: int)
signal player_health_changed(new_health: float)
signal level_completed
signal game_over

func _ready():
	load_game()

func collect_coin(amount: int = 1):
	coins_collected += amount
	total_coins += amount  # Adicionar imediatamente ao total
	save_game()  # Salvar imediatamente
	coin_collected.emit(amount)

func add_coins_to_total():
	# Adiciona as moedas coletadas no nível ao total
	total_coins += coins_collected
	save_game()

func set_total_coins(amount: int):
	total_coins = amount
	save_game()

func change_player_health(amount: float):
	player_health += amount
	player_health = max(0.0, player_health) 
	player_health_changed.emit(player_health)
	
	if player_health <= 0:
		game_over.emit()

func next_level():
	current_level += 1

func unlock_player2():
	if not player2_unlocked and total_coins >= 60:
		total_coins -= 60
		player2_unlocked = true
		save_game()
		return true
	return false

func save_game():
	var config = ConfigFile.new()
	config.set_value("player", "total_coins", total_coins)
	config.set_value("player", "player2_unlocked", player2_unlocked)
	config.save(SAVE_FILE_PATH)

func load_game():
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	if err == OK:
		total_coins = config.get_value("player", "total_coins", 0)
		player2_unlocked = config.get_value("player", "player2_unlocked", false)

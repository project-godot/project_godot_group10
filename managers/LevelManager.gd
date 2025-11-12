class_name LevelManager
extends Node

const MAX_LEVELS: int = 3
var unlocked_levels: int = 1

func get_max_unlocked_level() -> int:
	return unlocked_levels

func unlock_next_level() -> void:
	if unlocked_levels < MAX_LEVELS:
		unlocked_levels += 1
		print("Novo nível desbloqueado: ", unlocked_levels)
	else:
		print("Todos os níveis já foram desbloqueados!")

func reset_levels() -> void:
	unlocked_levels = 1
	print("Níveis resetados!")

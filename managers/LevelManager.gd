class_name LevelManager
extends Node

var unlocked_levels: int = 3

func get_max_unlocked_level() -> int:
	return unlocked_levels

func unlock_next_level() -> void:
	unlocked_levels += 1
	print("Novo nível desbloqueado: ", unlocked_levels)

func reset_levels() -> void:
	unlocked_levels = 1
	print("Níveis resetados!")

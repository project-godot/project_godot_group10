class_name LevelManager
extends RefCounted

# setando que apenas 1 nivel é desbloqueado
var unlocked_levels: int = 1

# função de verificar niveis desbloqueado
func get_max_unlocked_level() -> int:
	return unlocked_levels

# função para desbloquear niveis
func unlock_next_level() -> void:
	unlocked_levels += 1
	print("Novo nível desbloqueado: ", unlocked_levels)

# função para resetar os leveis
func reset_levels() -> void:
	unlocked_levels = 1
	print("Níveis resetados!")

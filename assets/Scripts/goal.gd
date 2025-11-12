extends Area2D

@onready var transition: CanvasLayer = $"../transition"
@export var proximo_nivel: String = ""

func _ready():
	# Configurar collision_mask para detectar apenas o Player (camada 2)
	collision_mask = 2
	
	# Desabilitar detecção de colisão inicialmente
	monitoring = false
	monitorable = false
	# Aguardar um pouco antes de habilitar
	await get_tree().create_timer(0.3).timeout
	# Habilitar detecção de colisão
	monitoring = true
	monitorable = true
	
	# Se proximo_nivel não estiver configurado, tentar detectar automaticamente
	if proximo_nivel == "":
		proximo_nivel = _detect_next_level()
		if proximo_nivel == "":
			print("AVISO: próximo_nivel não está configurado no goal e não foi possível detectar automaticamente!")
	
	# Debug
	if not transition:
		print("ERRO: Transition não encontrado!")

func _detect_next_level() -> String:
	# Tenta detectar o próximo nível baseado no nome da cena atual
	var current_scene = get_tree().current_scene.scene_file_path
	if "level1" in current_scene.to_lower():
		return "res://levels/level2.tscn"
	elif "level2" in current_scene.to_lower():
		return "res://levels/level3.tscn"
	elif "level3" in current_scene.to_lower():
		# Último nível - pode voltar ao menu ou fazer algo diferente
		return "res://main/LevelSelect.tscn"
	return ""

func _on_body_entered(body):
	# Filtrar apenas CharacterBody2D (Player) e ignorar StaticBody2D (Terrain, etc)
	if not body is CharacterBody2D:
		return
	
	# Verificar se é o Player pelo nome ou grupo
	if body.name == "Player" or body.is_in_group("player"):
		print("Player entrou no goal! Próximo nível: ", proximo_nivel)
		if proximo_nivel != "":
			if transition:
				transition._change_scene(proximo_nivel)
			else:
				print("ERRO: Transition não encontrado!")
		else:
			print("Nenhum nível definido para carregar.")

extends Area2D

var transition: CanvasLayer
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
	
	# Tentar encontrar o transition node - pode estar em diferentes locais dependendo da estrutura da cena
	transition = get_tree().current_scene.get_node_or_null("menu/transition")
	if not transition:
		# Tentar caminho alternativo caso o transition esteja diretamente no root
		transition = get_tree().current_scene.get_node_or_null("transition")
	
	# Se proximo_nivel não estiver configurado, tentar detectar automaticamente
	if proximo_nivel == "":
		proximo_nivel = _detect_next_level()
		if proximo_nivel == "":
			print("AVISO: próximo_nivel não está configurado no goal e não foi possível detectar automaticamente!")
	
	# Debug
	if not transition:
		print("ERRO: Transition não encontrado! Verifique se o nó 'menu/transition' existe na cena.")

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

func _unlock_next_level() -> void:
	# Desbloqueia o próximo nível baseado no nível atual
	var current_scene = get_tree().current_scene.scene_file_path
	var current_scene_lower = current_scene.to_lower()
	
	# Verificar se estamos em um nível válido antes de desbloquear
	if "level1" in current_scene_lower or "level2" in current_scene_lower or "level3" in current_scene_lower:
		ManagerLevel.unlock_next_level()

func _on_body_entered(body):
	# Filtrar apenas CharacterBody2D (Player) e ignorar StaticBody2D (Terrain, etc)
	if not body is CharacterBody2D:
		return
	
	# Verificar se é o Player pelo nome ou grupo
	if body.name == "Player" or body.is_in_group("player"):
		print("Player entrou no goal! Próximo nível: ", proximo_nivel)
		
		# As moedas já foram adicionadas ao total quando coletadas
		# Apenas resetar coins_collected para o próximo nível
		GameManager.coins_collected = 0
		
		# Desbloquear o próximo nível quando o player entra na caverna
		_unlock_next_level()
		
		if proximo_nivel != "":
			if transition:
				print("Iniciando transição para: ", proximo_nivel)
				transition._change_scene(proximo_nivel)
			else:
				print("ERRO: Transition não encontrado! Tentando mudança de cena direta...")
				# Fallback: mudança de cena direta se o transition não for encontrado
				get_tree().change_scene_to_file(proximo_nivel)
		else:
			print("Nenhum nível definido para carregar.")

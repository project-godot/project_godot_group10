extends CanvasLayer

@onready var health_container = $HealthContainer

const MAX_HEALTH = 10  # 5 full hearts (each heart = 2 health points)
# Ajuste: Carregando a sua cena da espada
var life_icon_scene = preload("res://levels/sword.tscn") 
var player_connected = false

func _ready():
	# Conectar ao sinal do Player quando disponível
	call_deferred("_connect_to_player")
	
	# Também tentar conectar após um pequeno delay caso o player ainda não esteja pronto
	get_tree().create_timer(0.5).timeout.connect(_connect_to_player)

func _connect_to_player():
	if player_connected:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed"):
			if not player_connected:
				player.health_changed.connect(_on_health_changed)
				player_connected = true
				# Atualizar UI inicial
				if player.health > 0:
					_on_health_changed(player.health)
				else:
					_on_health_changed(GameManager.player_health)
		else:
			# Fallback: conectar via GameManager
			if not GameManager.player_health_changed.is_connected(_on_health_changed):
				GameManager.player_health_changed.connect(_on_health_changed)
				player_connected = true
			_on_health_changed(GameManager.player_health)
	else:
		# Se não encontrar o player, tentar conectar via GameManager
		if not GameManager.player_health_changed.is_connected(_on_health_changed):
			GameManager.player_health_changed.connect(_on_health_changed)
		_on_health_changed(GameManager.player_health)

func _on_health_changed(new_health: float):
	# Limpar ícones existentes
	for child in health_container.get_children():
		child.queue_free()
	
	# Sistema de corações: cada coração representa 2 pontos de vida
	# Calcular quantos corações completos e meios são necessários
	var total_hearts = int(MAX_HEALTH / 2.0)  # Número total de corações (5 hearts)
	var full_hearts = int(new_health / 2.0)  # Corações completos (divisão inteira)
	var has_half = (new_health - (full_hearts * 2.0)) >= 1.0  # Se tem meio coração
	
	# Criar corações
	for i in range(total_hearts):
		var icon = life_icon_scene.instantiate() 
		health_container.add_child(icon)
		
		if i < full_hearts:
			# Coração completo
			icon.set_full()
		elif i == full_hearts and has_half:
			# Meio coração
			icon.set_half()
		else:
			# Coração vazio
			icon.set_empty()

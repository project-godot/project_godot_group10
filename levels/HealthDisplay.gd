extends CanvasLayer

@onready var health_container = $HealthContainer

const MAX_HEALTH = 5
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

func _on_health_changed(new_health: int):
	# Limpar ícones existentes
	for child in health_container.get_children():
		child.queue_free()
	
	# Criar ícones de vida (espadas)
	for i in range(MAX_HEALTH):
		# Ajuste: Renomeado de 'heart' para 'icon'
		var icon = life_icon_scene.instantiate() 
		health_container.add_child(icon)
		
		# Se a vida é menor que o índice, mostrar ícone "vazio"
		if i >= new_health:
			icon.set_empty() # Esta função DEVE existir no script da sua espada
		else:
			icon.set_full() # Esta função DEVE existir no script da sua espada

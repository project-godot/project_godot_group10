extends Control

@onready var player2_button = $VBoxContainer/Player2Container/Player2Button
@onready var player2_price_label = $VBoxContainer/Player2Container/PriceLabel
@onready var player2_status_label = $VBoxContainer/Player2Container/StatusLabel
@onready var total_coins_label = $VBoxContainer/TotalCoinsLabel

const PLAYER2_PRICE = 60

func _ready():
	# Garantir que o GameManager está carregado
	if not GameManager:
		push_error("GameManager não encontrado! Verifique se está configurado como autoload.")
		return
	
	# Conectar o sinal do botão se não estiver conectado
	if not player2_button.pressed.is_connected(_on_player2_button_pressed):
		player2_button.pressed.connect(_on_player2_button_pressed)
	
	update_shop_display()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			update_shop_display()

func update_shop_display():
	if not GameManager:
		return
	
	# Atualizar total de moedas
	if total_coins_label:
		total_coins_label.text = "Total Coins: " + str(GameManager.total_coins)
	
	# Atualizar estado do player2
	if GameManager.player2_unlocked:
		if player2_button:
			player2_button.disabled = true
		if player2_price_label:
			player2_price_label.text = ""
		if player2_status_label:
			player2_status_label.text = "✓ Unlocked"
			player2_status_label.modulate = Color.GREEN
		# Escurecer a imagem quando desbloqueado
		if player2_button and player2_button.has_node("Player2Image"):
			player2_button.get_node("Player2Image").modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		if player2_button:
			player2_button.disabled = false
		if player2_price_label:
			player2_price_label.text = "Price: " + str(PLAYER2_PRICE) + " coins"
		# Restaurar cor normal da imagem
		if player2_button and player2_button.has_node("Player2Image"):
			player2_button.get_node("Player2Image").modulate = Color.WHITE
		
		if player2_status_label:
			if GameManager.total_coins >= PLAYER2_PRICE:
				player2_status_label.text = "Click to unlock"
				player2_status_label.modulate = Color.WHITE
			else:
				var needed = PLAYER2_PRICE - GameManager.total_coins
				player2_status_label.text = "Not enough coins (" + str(needed) + " needed)"
				player2_status_label.modulate = Color.RED

func _on_player2_button_pressed():
	if not GameManager:
		push_error("GameManager não encontrado!")
		return
	
	# Verificar se já está desbloqueado
	if GameManager.player2_unlocked:
		print("Player 2 já está desbloqueado!")
		return
	
	# Tentar desbloquear
	if GameManager.unlock_player2():
		update_shop_display()
		print("Player 2 unlocked! Total coins remaining: ", GameManager.total_coins)
		
		# Feedback visual de sucesso
		if player2_status_label:
			player2_status_label.text = "✓ Purchased!"
			player2_status_label.modulate = Color.GREEN
			_show_feedback_timer()
	else:
		print("Not enough coins to unlock Player 2! You have: ", GameManager.total_coins, " but need: ", PLAYER2_PRICE)
		
		# Feedback visual de erro
		if player2_status_label:
			player2_status_label.text = "Not enough coins!"
			player2_status_label.modulate = Color.RED
			_show_feedback_timer()

func _show_feedback_timer():
	# Usar um timer para atualizar após feedback
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_on_feedback_timer_timeout)

func _on_feedback_timer_timeout():
	update_shop_display()

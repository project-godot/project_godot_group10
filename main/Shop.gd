extends Control

@onready var player2_button = $VBoxContainer/Player2Container/Player2Button
@onready var player2_price_label = $VBoxContainer/Player2Container/PriceLabel
@onready var player2_status_label = $VBoxContainer/Player2Container/StatusLabel
@onready var total_coins_label = $VBoxContainer/TotalCoinsLabel

const PLAYER2_PRICE = 60

func _ready():
	update_shop_display()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			update_shop_display()

func update_shop_display():
	# Atualizar total de moedas
	total_coins_label.text = "Total Coins: " + str(GameManager.total_coins)
	
	# Atualizar estado do player2
	if GameManager.player2_unlocked:
		player2_button.disabled = true
		player2_price_label.text = ""
		player2_status_label.text = "✓ Unlocked"
		player2_status_label.modulate = Color.GREEN
		# Escurecer a imagem quando desbloqueado
		if player2_button.has_node("Player2Image"):
			player2_button.get_node("Player2Image").modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		player2_button.disabled = false
		player2_price_label.text = "Price: " + str(PLAYER2_PRICE) + " coins"
		# Restaurar cor normal da imagem
		if player2_button.has_node("Player2Image"):
			player2_button.get_node("Player2Image").modulate = Color.WHITE
		
		if GameManager.total_coins >= PLAYER2_PRICE:
			player2_status_label.text = "Click to unlock"
			player2_status_label.modulate = Color.WHITE
		else:
			player2_status_label.text = "Not enough coins (" + str(PLAYER2_PRICE - GameManager.total_coins) + " needed)"
			player2_status_label.modulate = Color.RED

func _on_player2_button_pressed():
	if GameManager.unlock_player2():
		update_shop_display()
		print("Player 2 unlocked!")
	else:
		print("Not enough coins to unlock Player 2!")
		update_shop_display()

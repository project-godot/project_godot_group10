extends CanvasLayer

@onready var button_back = $Panel/VContainer/HContainer/ButtonBack
@onready var button_continue = $Panel/VContainer/HContainer/ButtonContinue
@onready var score_label = $Panel/VContainer/ScoreLabel

func _ready():
	button_back.pressed.connect(_on_back_pressed)
	button_continue.pressed.connect(_on_continue_pressed)

	button_back.mouse_exited.connect(_on_mouse_exited.bind(button_back))
	button_back.mouse_entered.connect(_on_mouse_entered.bind(button_back))
	button_continue.mouse_exited.connect(_on_mouse_exited.bind(button_continue))
	button_continue.mouse_entered.connect(_on_mouse_entered.bind(button_continue))
	
	update_score()

# volta pro menu de seleção de levels 
func _on_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main/LevelSelect.tscn")

# continua o jogo
func _on_continue_pressed():
	get_tree().paused = false
	queue_free()

# atualiza o valode de moedas do pause menu
func update_score():
	var coins = GameManager.coins_collected
	score_label.text = "Score: " + str(coins)

# função de interação do mouse
func _on_mouse_exited(button: Button):
	button.modulate.a = 0.5

func _on_mouse_entered(button: Button):
	button.modulate.a = 1.0

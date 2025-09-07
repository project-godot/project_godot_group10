extends CanvasLayer

@onready var score_label = $ScoreLabel

func _ready():
	GameManager.coin_collected.connect(_on_coin_collected)
	update_score()

func _on_coin_collected(amount: int):
	update_score()

func update_score():
	score_label.text = "Score: " + str(GameManager.coins_collected)

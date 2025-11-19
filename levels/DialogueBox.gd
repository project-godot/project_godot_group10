extends CanvasLayer

@onready var dialogue_label = $Panel/VBoxContainer/DialogueLabel
@onready var continue_button = $Panel/VBoxContainer/ContinueButton

var dialogue_text: String = ""
var is_active: bool = false

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)

func _input(event):
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_on_continue_pressed()

func show_dialogue(text: String):
	dialogue_text = text
	dialogue_label.text = dialogue_text
	is_active = true
	visible = true
	# Pausar o jogo enquanto o diálogo está aberto
	get_tree().paused = true

func _on_continue_pressed():
	is_active = false
	visible = false
	# Despausar o jogo
	get_tree().paused = false
	# Remover o diálogo após um pequeno delay para garantir que o jogo foi despausado
	call_deferred("queue_free")


class_name LevelSelect
extends Control

@onready var grid_containerlevels: GridContainer = $GridContainerlevels
@onready var back_button: Button = $BackButton

var level_manager: LevelManager

func _ready() -> void:
	# Usa o LevelManager global em vez de criar uma nova instância
	level_manager = ManagerLevel
	setup_level_buttons()

# definir se nivel está bloqueado/desbloqueado
func setup_level_buttons() -> void:
	var buttons = grid_containerlevels.get_children()
	const MAX_LEVELS = 3
	
	# Processar apenas os primeiros 3 botões
	for i in range(min(buttons.size(), MAX_LEVELS)):
		var button = buttons[i]
		var level_num = i + 1
		
		var unlocked_levels = level_manager.get_max_unlocked_level()
		
		if level_num <= unlocked_levels:
			button.text = "Nível " + str(level_num)
			button.modulate = Color.WHITE
			button.disabled = false
			button.pressed.connect(start_level.bind(level_num))
		else:
			button.text = "Nível " + str(level_num) + " 🔒"
			button.modulate = Color.GRAY
			button.disabled = true
	
	# Esconder botões extras se existirem
	for i in range(MAX_LEVELS, buttons.size()):
		buttons[i].visible = false

#  função de inicar nivel
func start_level(level_number: int) -> void:
	get_tree().change_scene_to_file("res://levels/level" + str(level_number) + ".tscn")

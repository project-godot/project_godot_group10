class_name LevelSelect
extends Control

@onready var grid_containerlevels: GridContainer = $GridContainerlevels
@onready var back_button: Button = $BackButton

var level_manager: LevelManager

func _ready() -> void:
	level_manager = LevelManager.new()
	setup_level_buttons()

# definir se nivel está bloqueado/desbloqueado
func setup_level_buttons() -> void:
	var buttons = grid_containerlevels.get_children()
	
	for i in range(buttons.size()):
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

#  função de inicar nivel
func start_level(level_number: int) -> void:
	print("Iniciando nível: ", level_number)
	get_tree().change_scene_to_file("res://levels/level" + str(level_number) + ".tscn")

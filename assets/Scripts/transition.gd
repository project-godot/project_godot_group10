extends CanvasLayer

@onready var color_rect: ColorRect = $color_rect
@export var show_on_start: bool = false

func _ready():
	if show_on_start:
		show_new_scene()
	else:
		# Garantir que o threshold está em 0 (transparente) no início
		if color_rect:
			color_rect.threshold = 0.0

func _change_scene(path,delay = 0.5):
	if not color_rect:
		print("ERRO: ColorRect não encontrado!")
		return
	var scene_transition = get_tree().create_tween()
	scene_transition.tween_property(color_rect, "threshold", 1.0, 0.5).set_delay(delay)
	await scene_transition.finished
	assert(get_tree().change_scene_to_file(path) == OK)
	
func show_new_scene():
	if not color_rect:
		return
	var show_transition = get_tree().create_tween()
	show_transition.tween_property(color_rect, "threshold", 0.0, 0.5).from(1.0)

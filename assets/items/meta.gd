extends Area2D

@onready var transition: CanvasLayer = $"../transition"
@export var proximo_level: String = ""

func _on_body_entered(body):
	if body.name == "Player" and proximo_level != "":
		transition.change_scene(proximo_level)
	else:
		print("no scene loaded")

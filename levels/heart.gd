extends Control

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func set_empty():
	if animated_sprite:
		animated_sprite.play("empty")

func set_half():
	if animated_sprite:
		animated_sprite.play("half")

func set_full():
	if animated_sprite:
		animated_sprite.play("full")

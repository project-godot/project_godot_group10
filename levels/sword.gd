extends Control

@onready var full_heart = $FullHeart
@onready var empty_heart = $EmptyHeart

func set_empty():
	full_heart.visible = false
	empty_heart.visible = true

func set_full():
	full_heart.visible = true
	empty_heart.visible = false

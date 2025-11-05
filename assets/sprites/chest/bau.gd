extends StaticBody2D

@export var vida_max = 3
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d = $Area2D
@onready var timer = $Timer

var vida: int = vida_max
var open: bool = false



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not open:
		take_damage(1)
		
func take_damage(amount: int):
	vida -= amount
	if vida <= 0:
		open_bau()
		
func open_bau():
	open = true
	animation.play("open")
	call_deferred("drop_itens")
	timer.start(2.0)
	
func drop_itens():
	var moeda = preload("res://assets/items/coin.tscn").instantiate()
	get_parent().add_child(moeda)
	moeda.position = position + Vector2(randf_range(-40,40),0)

func _on_timer_timeout():
	queue_free()
	

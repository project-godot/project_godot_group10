extends StaticBody2D

@export var vida_max = 3
@export var coin_drop_count = 5  # Quantidade de moedas que o baú dropa

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var timer: Timer = $Timer

var vida: int = vida_max
var open: bool = false
var has_damaged_this_hit: bool = false  # Evitar múltiplos hits no mesmo ataque


func _ready():
	# Adicionar ao grupo de baús para o player poder atacá-lo
	add_to_group("chests")
	
	# Conectar sinal do area (se ainda não estiver conectado)
	if not area_2d.body_entered.is_connected(_on_area_2d_body_entered):
		area_2d.body_entered.connect(_on_area_2d_body_entered)


func _on_area_2d_body_entered(body: Node2D) -> void:
	# Não usar mais - o player vai detectar via seu attack_area
	pass
		
		
func take_damage(amount: int):
	if open or vida <= 0:
		return
		
	vida -= amount
	print("Baú recebeu ", amount, " de dano! Vida restante: ", vida)
	
	if vida <= 0:
		open_bau()


func open_bau():
	if open:
		return
		
	open = true
	# Remover colisão para que o player possa passar
	var collision = get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)
	
	# Se tiver animação "open", usar, senão apenas dropar itens
	if animation and animation.sprite_frames.has_animation("open"):
		animation.play("open")
		call_deferred("drop_itens")
		timer.start(2.0)
	else:
		# Se não tiver animação, dropar itens imediatamente
		drop_itens()
		timer.start(1.0)
	
	
func drop_itens():
	var coin_scene = preload("res://assets/items/coin.tscn")
	
	# Dropar múltiplas moedas
	for i in range(coin_drop_count):
		var moeda = coin_scene.instantiate()
		# Adicionar na cena atual (não no parent)
		get_tree().current_scene.add_child(moeda)
		# Posicionar moedas em uma área espalhada
		var offset_x = randf_range(-30, 30)
		var offset_y = randf_range(-20, 10)
		moeda.global_position = global_position + Vector2(offset_x, offset_y)
	
	
func _on_timer_timeout() -> void:
	queue_free()

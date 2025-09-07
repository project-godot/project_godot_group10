extends Area2D

# Esta função é chamada quando a moeda entra na cena
func _ready() -> void:
	# Conecta o sinal de body_entered
	body_entered.connect(_on_body_entered)
	
	# Conecta o sinal de animação terminada
	$AnimatedSprite2D.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	
	# Desativa a colisão e o processamento para evitar que a moeda seja coletada antes de ser instanciada
	# e para garantir que o jogador só possa coletá-la uma vez.
	set_process(true)
	$CollisionShape2D.disabled = false

# Esta função é chamada quando um corpo (o seu jogador) entra na área da moeda
func _on_body_entered(body: Node2D) -> void:
	# Verifique se o corpo que entrou é o jogador
	if body.is_in_group("player"):  # Usa grupo em vez de nome
		# Notifica o GameManager que uma moeda foi coletada
		GameManager.collect_coin(1)
		
		# Reproduz a animação de coleta
		$AnimatedSprite2D.play("collected")
		
		# Desativa a colisão da moeda para que ela não possa ser coletada novamente
		$CollisionShape2D.disabled = true
		
		# Desativa a lógica de processamento, pois não é mais necessária
		set_process(false)

# Esta função é chamada quando a animação do AnimatedSprite2D termina
func _on_animated_sprite_2d_animation_finished() -> void:
	# Remove a moeda da cena
	queue_free()

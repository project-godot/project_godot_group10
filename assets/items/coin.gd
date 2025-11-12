extends Area2D

var collected = false
var velocity = Vector2.ZERO
var gravity_force = 980.0
var is_falling = true

@onready var ground_check = $GroundCheck

func _ready():
	# Conecta o sinal de body_entered
	body_entered.connect(_on_body_entered)
	if ground_check:
		ground_check.enabled = true
		ground_check.collision_mask = 1  # Ensure it detects ground layer
	
	# Garantir que a moeda sempre começa caindo
	is_falling = true
	velocity.y = 0  # Start with no vertical velocity, gravity will take over

func _apply_initial_velocity(initial_vel: Vector2):
	# Para Area2D, aplicamos a velocidade diretamente
	velocity = initial_vel
	is_falling = true

func _physics_process(delta):
	if collected:
		return
	
	# Sempre aplicar gravidade se não estiver no chão
	if ground_check:
		ground_check.force_raycast_update()
		var is_on_ground = ground_check.is_colliding()
		
		if not is_on_ground:
			# Não está no chão, aplicar gravidade
			is_falling = true
			velocity.y += gravity_force * delta
			
			# Limitar velocidade de queda
			if velocity.y > 500:
				velocity.y = 500
			
			# Aplicar movimento
			position += velocity * delta
			
			# Reduzir velocidade horizontal gradualmente (atrito)
			velocity.x = lerp(velocity.x, 0.0, 2.0 * delta)
		else:
			# Está no chão, parar a queda
			if is_falling:
				velocity.y = 0
				is_falling = false
				# Ajustar posição para ficar exatamente em cima do chão
				var collision_point = ground_check.get_collision_point()
				global_position.y = collision_point.y - 5  # 5 pixels acima do ponto de colisão
			
			# Ainda pode ter movimento horizontal residual
			if abs(velocity.x) > 0.1:
				position.x += velocity.x * delta
				velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			else:
				velocity.x = 0
	else:
		# Se não tem ground_check, aplicar gravidade básica
		velocity.y += gravity_force * delta
		if velocity.y > 500:
			velocity.y = 500
		position += velocity * delta
		velocity.x = lerp(velocity.x, 0.0, 2.0 * delta)

func _on_body_entered(body: Node2D):
	if collected:
		return
	
	if body.is_in_group("player"):
		collected = true
		
		# Para o movimento imediatamente
		velocity = Vector2.ZERO
		is_falling = false
		
		# Efeito visual de coleta
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", scale * 1.5, 0.2)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
		
		# Notifica o GameManager
		GameManager.collect_coin(1)
		
		# Desativa a colisão
		if $CollisionShape2D:
			$CollisionShape2D.disabled = true
			
		# Toca animação se existir, senão só remove
		if $AnimatedSprite2D and $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation("collected"):
			$AnimatedSprite2D.play("collected")
			await $AnimatedSprite2D.animation_finished
			queue_free()
		else:
			await tween.finished
			queue_free()

func _on_animated_sprite_2d_animation_finished():
	# Método conectado via .tscn, mas a lógica já é tratada em _on_body_entered
	pass

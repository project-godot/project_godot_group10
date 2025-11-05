extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $LedgeCheck
@onready var attack_timer = $AttackTimer

const SPEED = 50.0
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 50.0 
const MAX_HEALTH = 3
const ATTACK_DAMAGE = 1

var direction_x = 1 
var player_node = null
var current_state = State.PATROL
var start_position: Vector2 
var left_limit: float  
var right_limit: float  
var attack_can_start = true
var health = MAX_HEALTH
var is_attacking = false
var attack_cooldown_timer = 0.0
var last_attack_time = 0.0
const ATTACK_COOLDOWN = 1.0  # 2 segundos entre ataques

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE
	
	# Conectar sinais
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Debug removido para limpar console

func _physics_process(delta):
	if current_state == State.DEAD:
		return
		
	if not is_on_floor():
		velocity.y += 980 * delta
	
	# Atualizar cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# Verificação manual de detecção do jogador (backup)
	if current_state == State.PATROL:
		check_for_player_manually()
	
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.CHASE:
			chase_state(delta)
		State.ATTACK:
			attack_state(delta)
	
	move_and_slide()

func patrol_state(_delta):
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1
	
	if is_on_floor() and not ledge_check.is_colliding():
		direction_x *= -1
			
	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED
	
	# Debug: mostrar estado de patrulha
	if int(position.x) % 100 == 0:  # Print a cada 100 pixels
		print("PATRULHA - Posição: ", position.x, " - Limites: ", left_limit, " a ", right_limit)

func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var distance_to_player = position.distance_to(player_node.position)
		
		# Se o jogador está muito longe, parar perseguição
		if distance_to_player > 300:
			current_state = State.PATROL
			player_node = null
			return
		
		# Se está no alcance de ataque e pode atacar
		if distance_to_player < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			print("⚔️ Atacando jogador!")
			
			# Causar dano UMA VEZ
			if player_node.has_method("take_damage"):
				player_node.take_damage(ATTACK_DAMAGE)
				print("💥 ATAQUE EXECUTADO! Dano causado ao jogador")
			
			# Iniciar ataque
			current_state = State.ATTACK
			is_attacking = true
			attack_cooldown_timer = ATTACK_COOLDOWN
			attack_timer.start()
			return
		
		# Perseguir o jogador
		var target_direction = sign(player_node.position.x - position.x)
		direction_x = target_direction
		animated_sprite.flip_h = direction_x < 0
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		current_state = State.PATROL
		animated_sprite.play("idle")

func attack_state(_delta):
	velocity.x = 0
	animated_sprite.play("attack")
	# O timer vai voltar para o estado de perseguição

func _on_detection_area_body_entered(body):
	print("DETECÇÃO: ", body.name, " - Grupos: ", body.get_groups())
	
	# Ignorar inimigos, terreno e outros objetos que não são jogador
	if body.is_in_group("enemies") or body.is_in_group("terrain") or body == self:
		print("Ignorando: ", body.name)
		return
	
	if body.is_in_group("player"):
		print("✅ JOGADOR DETECTADO! Mudando para perseguição")
		player_node = body
		current_state = State.CHASE
	else:
		print("❌ Objeto não é jogador: ", body.name)

func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL
		is_attacking = false

func _on_attack_timer_timeout():
	# Volta para perseguição após o ataque
	is_attacking = false
	
	# Verificar se o jogador ainda está próximo
	if player_node and is_instance_valid(player_node):
		var distance_to_player = position.distance_to(player_node.position)
		if distance_to_player < 200:
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	else:
		current_state = State.PATROL

func take_damage(damage: int):
	health -= damage
	print("Inimigo recebeu ", damage, " de dano. Vida restante: ", health)
	
	if health <= 0:
		die()
	else:
		# Animação de dano (se tiver)
		animated_sprite.play("hurt")

func die():
	current_state = State.DEAD
	animated_sprite.play("die")
	# Desabilitar colisão
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Remover após um tempo
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_attack_area_body_entered(body):
	# Esta função pode ser usada para detectar quando o jogador entra na área de ataque
	# Útil para ataques com área específica
	pass

func check_for_player_manually():
	# Buscar o jogador na cena manualmente
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var distance = position.distance_to(player.position)
		
		# Se o jogador está próximo (raio de 150 pixels)
		if distance < 150:
			print("🔍 DETECÇÃO MANUAL: Jogador encontrado a ", distance, " pixels")
			player_node = player
			current_state = State.CHASE

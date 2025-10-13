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
const ATTACK_COOLDOWN = 1.0 # 2 segundos entre ataques

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta):
	if current_state == State.DEAD:
		return
		
	if not is_on_floor():
		velocity.y += 980 * delta
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
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

# ▼▼▼▼▼▼▼▼▼▼ ÚNICA FUNÇÃO ALTERADA ▼▼▼▼▼▼▼▼▼▼
func patrol_state(_delta):
	animated_sprite.play("walk")
	animated_sprite.flip_h = direction_x < 0

	# CORRIGIDO: A lógica de virar agora está em um bloco if/elif
	# para evitar que duas condições de virar aconteçam ao mesmo tempo.
	
	# Condição 1: Chegou no limite da patrulha
	if position.x <= left_limit and direction_x < 0:
		direction_x = 1
		ledge_check.position.x *= -1 # ADICIONADO: Vira o detector de borda junto
	elif position.x >= right_limit and direction_x > 0:
		direction_x = -1
		ledge_check.position.x *= -1 # ADICIONADO: Vira o detector de borda junto

	# Condição 2: Chegou na beirada de uma plataforma
	# Este 'if' é separado para que a detecção de borda funcione em qualquer lugar.
	if is_on_floor() and not ledge_check.is_colliding():
		# Uma pequena espera para não virar instantaneamente e parecer mais natural
		await get_tree().create_timer(0.1).timeout
		if current_state == State.PATROL: # Checa se ainda está patrulhando
			direction_x *= -1
			ledge_check.position.x *= -1 # ADICIONADO: Vira o detector de borda junto

	velocity.x = direction_x * SPEED
# ▲▲▲▲▲▲▲▲▲▲ FIM DA FUNÇÃO ALTERADA ▲▲▲▲▲▲▲▲▲▲

func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var distance_to_player = position.distance_to(player_node.position)
		
		if distance_to_player > 300:
			current_state = State.PATROL
			player_node = null
			return
		
		if distance_to_player < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			print("⚔️ Atacando jogador!")
			
			if player_node.has_method("take_damage"):
				player_node.take_damage(ATTACK_DAMAGE)
				print("💥 ATAQUE EXECUTADO! Dano causado ao jogador")
			
			current_state = State.ATTACK
			is_attacking = true
			attack_cooldown_timer = ATTACK_COOLDOWN
			attack_timer.start()
			return
		
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

func _on_detection_area_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("terrain") or body == self:
		return
	
	if body.is_in_group("player"):
		player_node = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL
		is_attacking = false

func _on_attack_timer_timeout():
	is_attacking = false
	
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
		animated_sprite.play("hurt")

func die():
	current_state = State.DEAD
	animated_sprite.play("die")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_attack_area_body_entered(body):
	pass

func check_for_player_manually():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var distance = position.distance_to(player.position)
		
		if distance < 150:
			player_node = player
			current_state = State.CHASE

extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $Timer

const SPEED = 70.0
const ATTACK_RANGE = 60.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 6
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 10

var is_dead: bool = false
var levando_hit: bool = false
var direction_x: int = 1
var player_node = null
var current_state = State.PATROL
var start_position: Vector2
var left_limit: float
var right_limit: float
var health = MAX_HEALTH
var is_attacking = false
var attack_cooldown_timer = 0.0
var hurt_lock_timer: float = 0.0
var has_damaged_this_attack: bool = false
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.5
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_COOLDOWN = 0.4
const ATTACK_WINDUP = 0.3
const ATTACK_ACTIVE = 0.2

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE

	current_state = State.PATROL
	direction_x = 1

	# Conectar sinais (usando Callable para garantir compatibilidade)
	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	if attack_area:
		attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	if attack_timer:
		attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

	# Conectar animações
	if animated_sprite:
		animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

	# Desabilitar hitbox de ataque inicialmente
	if attack_area:
		attack_area.monitoring = false

	# Garantir que a DetectionArea está habilitada
	if detection_area:
		detection_area.monitoring = true
		detection_area.monitorable = true

	# Verificar corpos já sobrepostos e conectar ao player (se existir)
	call_deferred("_check_initial_overlap")
	call_deferred("_connect_to_player")
	call_deferred("_start_patrol")


func _start_patrol():
	if current_state == State.PATROL:
		if animated_sprite:
			animated_sprite.play("walk")
			animated_sprite.flip_h = direction_x > 0


func _check_initial_overlap():
	if not detection_area:
		return
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body and body.is_in_group("player"):
			player_node = body
			if current_state != State.DEAD:
				current_state = State.CHASE
			break


func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Travar comportamento enquanto leva dano
	if levando_hit:
		hurt_lock_timer -= delta
		if hurt_lock_timer <= 0.0:
			levando_hit = false
		velocity.x = 0
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += 980 * delta

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	# Reaquisição manual do player - sempre verificar para pegar player no chão
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
	check_for_player_manually()

	if player_node != null and is_instance_valid(player_node):
		current_state = State.CHASE
		return

	if is_on_wall():
		direction_x *= -1

	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1

	if animated_sprite:
		animated_sprite.flip_h = direction_x > 0
		animated_sprite.play("walk")

	velocity.x = direction_x * SPEED


func chase_state(_delta):
	# Garantir player válido
	if not player_node or not is_instance_valid(player_node):
		check_for_player_manually()
		if not player_node or not is_instance_valid(player_node):
			current_state = State.PATROL
			return

	# Calcular distância
	var dist = global_position.distance_to(player_node.global_position)

	# Se o player sair do range, voltar para patrulha
	if dist > 400:
		current_state = State.PATROL
		player_node = null
		return

	# Iniciar ataque se possível
	if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
		current_state = State.ATTACK
		is_attacking = true
		has_damaged_this_attack = false
		attack_elapsed = 0.0
		attack_cooldown_timer = ATTACK_COOLDOWN

		var attack_duration = 1.6
		if attack_timer:
			attack_timer.start(attack_duration)

		if animated_sprite:
			animated_sprite.play("attack")

		_start_attack_window()
		return

	# Perseguir
	var player_dir = sign(player_node.global_position.x - global_position.x)
	if player_dir != 0:
		direction_x = player_dir

	if animated_sprite:
		animated_sprite.flip_h = direction_x > 0
		animated_sprite.play("walk")

	velocity.x = direction_x * SPEED


func attack_state(_delta):
	# Atualizar direção em relação ao player
	if player_node and is_instance_valid(player_node):
		var player_dir = sign(player_node.global_position.x - global_position.x)
		if player_dir != 0:
			direction_x = player_dir

		if animated_sprite:
			animated_sprite.flip_h = direction_x > 0

		# Atualizar posição do AttackArea para ficar à frente
		if attack_area:
			attack_area.position.x = 100 if direction_x > 0 else -100

	# Movimento durante o ataque
	attack_elapsed += _delta
	if attack_elapsed <= ATTACK_LUNGE_TIME:
		velocity.x = direction_x * (SPEED * ATTACK_LUNGE_MULT)
	else:
		velocity.x = direction_x * (SPEED * ATTACK_DRIFT_MULT)

	# Garantir animação de ataque
	if animated_sprite and animated_sprite.animation != "attack":
		animated_sprite.play("attack")


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return
	if not body:
		return
	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
			has_damaged_this_attack = true
			print("Minotaur acertou o player!")


func _check_overlapping_bodies_in_attack_area():
	if not is_attacking or not attack_area or not attack_area.monitoring or has_damaged_this_attack:
		return

	var bodies = attack_area.get_overlapping_bodies()
	print("AttackArea overlapping bodies: ", bodies.size())
	for body in bodies:
		if body and body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(ATTACK_DAMAGE)
				has_damaged_this_attack = true
				print("Minotaur acertou o player (overlap check)! Player pos: ", body.global_position, " Minotaur pos: ", global_position)
				return


func _on_detection_area_body_entered(body):
	if not body:
		return
	if body.is_in_group("player"):
		player_node = body
		if current_state != State.DEAD:
			current_state = State.CHASE
			print("Minotaur detectou player via DetectionArea!")


func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL
		is_attacking = false


func _on_attack_timer_timeout():
	# Terminar o ataque e voltar para perseguição
	is_attacking = false
	has_damaged_this_attack = false
	if attack_area:
		attack_area.monitoring = false
		attack_area.position.x = 0

	if player_node != null and is_instance_valid(player_node):
		current_state = State.CHASE
	else:
		current_state = State.PATROL


func take_damage(damage: int):
	if current_state == State.DEAD or is_dead:
		return

	health -= damage

	if health <= 0:
		die()
	else:
		levando_hit = true
		hurt_lock_timer = 0.25
		# Interromper ataque se estiver atacando
		if is_attacking:
			is_attacking = false
			if attack_area:
				attack_area.monitoring = false
				attack_area.position.x = 0


func die():
	current_state = State.DEAD
	is_dead = true
	velocity = Vector2.ZERO
	if detection_area:
		detection_area.monitoring = false
	if attack_area:
		attack_area.monitoring = false
	if animated_sprite:
		animated_sprite.play("idle")
	var death_timer = get_tree().create_timer(1.1)
	death_timer.timeout.connect(Callable(self, "_on_death_complete"))


func _on_death_complete():
	_drop_coins()
	queue_free()


func _drop_coins():
	var coin_scene = preload("res://assets/items/coin.tscn")
	for i in range(COIN_DROP_COUNT):
		var coin = coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))


func check_for_player_manually():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	var player = players[0]
	if not is_instance_valid(player):
		return

	# Distâncias separadas
	var horizontal_dist = abs(global_position.x - player.global_position.x)
	var vertical_dist = player.global_position.y - global_position.y  # positivo se player está abaixo

	# Verificar se o player está à frente do minotaur
	var player_dir = sign(player.global_position.x - global_position.x)
	var is_in_front = (player_dir == direction_x) or (horizontal_dist < 50)

	# Detecção melhorada: range horizontal grande e tolerância vertical
	if horizontal_dist < 500 and vertical_dist >= -80 and vertical_dist < 80 and is_in_front:
		player_node = player
		if current_state == State.PATROL:
			current_state = State.CHASE
			print("Minotaur detectou player manualmente! Dist: ", horizontal_dist, " Vertical: ", vertical_dist, " Direção: ", player_dir)


func _start_attack_window() -> void:
	# Posicionar AttackArea à frente do minotaur baseado na direção
	if attack_area:
		attack_area.position.x = 100 if direction_x > 0 else -100

	# Windup -> ativar hitbox por ATTACK_ACTIVE -> desativar
	# Usando await para gerenciar timers de forma clara
	# Windup
	await get_tree().create_timer(ATTACK_WINDUP).timeout

	# Antes de ativar, verificar se ainda está em ataque
	if not is_attacking or current_state != State.ATTACK:
		# se não estiver atacando mais, resetar
		if attack_area:
			attack_area.monitoring = false
			attack_area.position.x = 0
		return

	if attack_area:
		attack_area.monitoring = true

	# Checagens imediatas para sobreposições
	call_deferred("_check_overlapping_bodies_in_attack_area")
	await get_tree().create_timer(0.01).timeout
	call_deferred("_check_overlapping_bodies_in_attack_area")
	await get_tree().create_timer(0.02).timeout
	call_deferred("_check_overlapping_bodies_in_attack_area")

	# Tempo ativo da janela de dano
	await get_tree().create_timer(ATTACK_ACTIVE).timeout

	# Desativar hitbox
	if attack_area:
		attack_area.monitoring = false
		attack_area.position.x = 0


func _connect_to_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player and player.has_signal("player_left_screen"):
			player.connect("player_left_screen", Callable(self, "_on_player_left_screen"))
	else:
		# tentar novamente depois de 0.5s
		await get_tree().create_timer(0.5).timeout
		_connect_to_player()


func _on_player_left_screen():
	if current_state == State.DEAD:
		return

	position = start_position
	velocity = Vector2.ZERO
	player_node = null
	current_state = State.PATROL
	is_attacking = false
	if animated_sprite:
		animated_sprite.play("walk")


func _on_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

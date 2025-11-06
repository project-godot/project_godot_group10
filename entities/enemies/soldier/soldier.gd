extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $RayCast2D
@onready var attack_timer = $Timer

const SPEED = 70.0
const ATTACK_RANGE = 45.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 4
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 8

var is_dead: bool = false
var levando_hit: bool = false
var direction_x = 1
var player_node = null
var current_state = State.PATROL
var start_position: Vector2
var left_limit: float
var right_limit: float
var health = MAX_HEALTH
var is_attacking = false
var attack_cooldown_timer = 0.0
const ATTACK_COOLDOWN = 0.4
var hurt_lock_timer: float = 0.0
var has_damaged_this_attack: bool = false
var combo_hit_count: int = 0
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.5
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_WINDUP_1 = 0.3   # Tempo antes de ativar o hitbox para attack
const ATTACK_WINDUP_2 = 0.4   # Tempo antes de ativar o hitbox para attack2
const ATTACK_WINDUP_COMBO_HIT1 = 0.35   # Tempo antes do primeiro hit do combo
const ATTACK_WINDUP_COMBO_HIT2 = 0.7    # Tempo antes do segundo hit do combo
const ATTACK_ACTIVE = 0.2  # Tempo que o hitbox fica ativo
var current_attack_animation: String = ""
var last_attack_type: String = ""  # Para rotacionar os ataques
var attack_sequence: Array[String] = ["attack", "attack2", "combo"]  # Sequência de ataques
var attack_index: int = 0  # Índice atual na sequência

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Conectar animações
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Garantir raycast de beirada ativo
	ledge_check.enabled = true

	# Desabilitar hitbox de ataque fora da janela ativa
	attack_area.monitoring = false

	# Iniciar com animação walk na patrulha
	animated_sprite.play("walk")

	call_deferred("_connect_to_player")


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

	# Reaquisição manual do player
	if player_node == null:
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
	# Manter o raycast de beirada à frente da direção atual
	# A posição Y deve ser relativa ao corpo do inimigo
	ledge_check.position.x = 17 * direction_x
	ledge_check.position.y = -9  # Resetar Y para manter consistente
	
	if position.x <= left_limit:
		direction_x = 1
		ledge_check.position.x = 17
	elif position.x >= right_limit:
		direction_x = -1
		ledge_check.position.x = -17

	# Verificar se há chão à frente antes de continuar
	if is_on_floor():
		ledge_check.force_raycast_update()
		if not ledge_check.is_colliding():
			direction_x *= -1
			ledge_check.position.x = 17 * direction_x

	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED


func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)

		# Se o player sair do range, voltar para patrulha
		if dist > 300:
			current_state = State.PATROL
			last_attack_type = ""
			attack_index = 0
			return

		# Se estiver perto o suficiente e não estiver atacando, atacar
		if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			current_state = State.ATTACK
			is_attacking = true
			has_damaged_this_attack = false
			combo_hit_count = 0
			attack_elapsed = 0.0
			attack_cooldown_timer = ATTACK_COOLDOWN
			
			# Selecionar próximo ataque na sequência
			current_attack_animation = attack_sequence[attack_index]
			last_attack_type = current_attack_animation
			attack_index = (attack_index + 1) % attack_sequence.size()
			
			# Definir duração do timer baseado no ataque
			var attack_duration = _get_attack_duration(current_attack_animation)
			attack_timer.start(attack_duration)
			
			# Iniciar a animação imediatamente
			animated_sprite.play(current_attack_animation)
			_start_attack_window()
			return

		# Perseguir o player
		direction_x = sign(player_node.global_position.x - global_position.x)
		ledge_check.position.x = 17 * direction_x
		ledge_check.position.y = -9  # Manter Y consistente
		animated_sprite.flip_h = direction_x < 0
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		current_state = State.PATROL


func attack_state(_delta):
	# Recalcular direção em relação ao player
	if player_node and is_instance_valid(player_node):
		direction_x = sign(player_node.global_position.x - global_position.x)
		ledge_check.position.x = 17 * direction_x
		ledge_check.position.y = -9  # Manter Y consistente
		animated_sprite.flip_h = direction_x < 0

	# Aplicar movimento durante o ataque
	attack_elapsed += _delta
	if attack_elapsed <= ATTACK_LUNGE_TIME:
		velocity.x = direction_x * (SPEED * ATTACK_LUNGE_MULT)
	else:
		velocity.x = direction_x * (SPEED * ATTACK_DRIFT_MULT)

	# Garantir que a animação de ataque está tocando
	if current_attack_animation != "" and animated_sprite.animation != current_attack_animation:
		animated_sprite.play(current_attack_animation)


func _get_attack_duration(attack_name: String) -> float:
	# Retorna a duração aproximada de cada ataque em segundos
	match attack_name:
		"attack":
			return 0.5  # 4 frames / 10 fps = 0.4s + buffer
		"attack2":
			return 0.7  # 6 frames / 10 fps = 0.6s + buffer
		"combo":
			return 1.1  # 10 frames / 10 fps = 1.0s + buffer
		_:
			return 0.5


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return

	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
			has_damaged_this_attack = true
			# Para o combo, permitir múltiplos hits
			if current_attack_animation == "combo":
				# O combo tem dois hits separados, então não bloqueia aqui
				pass


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_node = body
		current_state = State.CHASE


func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL
		is_attacking = false
		last_attack_type = ""
		attack_index = 0


func _on_attack_timer_timeout():
	# Terminar o ataque e voltar para perseguição
	is_attacking = false
	has_damaged_this_attack = false
	attack_area.monitoring = false
	current_attack_animation = ""
	
	# Voltar para o estado apropriado
	if player_node != null and is_instance_valid(player_node):
		current_state = State.CHASE
	else:
		current_state = State.PATROL


func take_damage(damage: int):
	if current_state == State.DEAD:
		return

	health -= damage

	if health <= 0:
		die()
	else:
		levando_hit = true
		hurt_lock_timer = 0.25
		# Não tem animação hurt, apenas pausar movimento


func die():
	current_state = State.DEAD
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	var death_timer = get_tree().create_timer(1.1)
	death_timer.timeout.connect(_on_death_complete)


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
	if players.size() > 0:
		var player = players[0]
		if global_position.distance_to(player.global_position) < 220:
			player_node = player
			current_state = State.CHASE


func _start_attack_window():
	if current_attack_animation == "attack":
		# Attack: um único hit
		var windup_timer = get_tree().create_timer(ATTACK_WINDUP_1)
		windup_timer.timeout.connect(func():
			if not is_attacking or current_attack_animation != "attack":
				return
			_activate_hitbox()
		)
	elif current_attack_animation == "attack2":
		# Attack2: um único hit
		var windup_timer = get_tree().create_timer(ATTACK_WINDUP_2)
		windup_timer.timeout.connect(func():
			if not is_attacking or current_attack_animation != "attack2":
				return
			_activate_hitbox()
		)
	elif current_attack_animation == "combo":
		# Combo: dois hits
		# Primeiro hit
		var hit1_timer = get_tree().create_timer(ATTACK_WINDUP_COMBO_HIT1)
		hit1_timer.timeout.connect(func():
			if not is_attacking or current_attack_animation != "combo":
				return
			combo_hit_count = 1
			has_damaged_this_attack = false  # Resetar para permitir segundo hit
			_activate_hitbox()
		)
		# Segundo hit
		var hit2_timer = get_tree().create_timer(ATTACK_WINDUP_COMBO_HIT2)
		hit2_timer.timeout.connect(func():
			if not is_attacking or current_attack_animation != "combo":
				return
			combo_hit_count = 2
			has_damaged_this_attack = false  # Resetar para permitir segundo hit
			_activate_hitbox()
		)


func _activate_hitbox():
	# Ativar o monitoring primeiro
	attack_area.monitoring = true
	
	# Checagem imediata de corpos já sobrepostos
	# Usar call_deferred para garantir que o monitoring está totalmente ativo
	call_deferred("_check_overlapping_bodies_immediate")
	
	# Também fazer checagem após um pequeno delay como backup
	var check_timer = get_tree().create_timer(0.02)
	check_timer.timeout.connect(func():
		if not has_damaged_this_attack and is_attacking and attack_area.monitoring:
			_check_overlapping_bodies_immediate()
	)
	
	# Tempo ativo - janela de dano
	var active_timer = get_tree().create_timer(ATTACK_ACTIVE)
	active_timer.timeout.connect(func():
		attack_area.monitoring = false
	)


func _check_overlapping_bodies_immediate():
	# Checagem de corpos já sobrepostos quando o hitbox é ativado
	if not has_damaged_this_attack and is_attacking and attack_area.monitoring:
		var bodies = attack_area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("player") and b.has_method("take_damage"):
				b.take_damage(ATTACK_DAMAGE)
				has_damaged_this_attack = true
				break


func _connect_to_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_signal("player_left_screen"):
			player.player_left_screen.connect(_on_player_left_screen)
	else:
		get_tree().create_timer(0.5).timeout.connect(_connect_to_player)


func _on_player_left_screen():
	if current_state == State.DEAD:
		return

	position = start_position
	velocity = Vector2.ZERO
	player_node = null
	current_state = State.PATROL
	is_attacking = false
	last_attack_type = ""
	attack_index = 0
	animated_sprite.play("walk")


func _on_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

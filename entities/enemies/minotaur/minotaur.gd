extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var attack_timer = $Timer

const SPEED = 70.0
const ATTACK_RANGE = 60.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 6
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 10

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
	
	# Garantir que o estado inicial seja PATROL
	current_state = State.PATROL
	direction_x = 1  # Começar movendo para a direita

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Conectar animações
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Desabilitar hitbox de ataque fora da janela ativa
	attack_area.monitoring = false
	
	# Garantir que a DetectionArea está habilitada e monitorando
	detection_area.monitoring = true
	detection_area.monitorable = false
	
	# Verificar se há corpos já sobrepostos na DetectionArea
	call_deferred("_check_initial_overlap")

	call_deferred("_connect_to_player")
	
	# Iniciar com animação walk na patrulha (após setup)
	call_deferred("_start_patrol")

func _start_patrol():
	# Garantir que está em patrulha e começando a andar
	if current_state == State.PATROL:
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction_x > 0  # Invertido para o minotaur

func _check_initial_overlap():
	# Verificar se há corpos já sobrepostos na DetectionArea quando o inimigo spawna
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
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
	# Verificar player manualmente durante patrulha também (sempre verificar)
	check_for_player_manually()
	
	# Se detectou player, mudar para CHASE imediatamente
	if player_node != null and is_instance_valid(player_node):
		current_state = State.CHASE
		return
	
	# Verificar se colidiu com parede - se sim, inverter direção
	if is_on_wall():
		direction_x *= -1
	
	# Verificar limites de patrulha
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1

	animated_sprite.flip_h = direction_x > 0  # Invertido para o minotaur
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED

func chase_state(_delta):
	# Sempre verificar se o player ainda está válido
	if not player_node or not is_instance_valid(player_node):
		check_for_player_manually()
		if not player_node or not is_instance_valid(player_node):
			current_state = State.PATROL
			return
	
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)

		# Se o player sair do range, voltar para patrulha
		if dist > 400:  # Aumentado para não perder o player facilmente
			current_state = State.PATROL
			player_node = null
			return

		# Se estiver perto o suficiente e não estiver atacando, atacar
		if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			current_state = State.ATTACK
			is_attacking = true
			has_damaged_this_attack = false
			attack_elapsed = 0.0
			attack_cooldown_timer = ATTACK_COOLDOWN
			
			# Definir duração do timer baseado no ataque
			# A animação tem ~1.6 segundos (16 frames / speed 10.0)
			var attack_duration = 1.6  # Duração completa da animação de ataque
			attack_timer.start(attack_duration)
			
			# Iniciar a animação imediatamente
			animated_sprite.play("attack")
			print("Minotaur iniciou ataque! Player dist: ", dist, " Player pos: ", player_node.global_position, " Minotaur pos: ", global_position)
			_start_attack_window()
			return

		# Perseguir o player
		var player_dir = sign(player_node.global_position.x - global_position.x)
		# Se player estiver exatamente na mesma posição X, manter direção atual
		if player_dir != 0:
			direction_x = player_dir
		animated_sprite.flip_h = direction_x > 0  # Invertido para o minotaur
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		current_state = State.PATROL


func attack_state(_delta):
	# Recalcular direção em relação ao player
	if player_node and is_instance_valid(player_node):
		var player_dir = sign(player_node.global_position.x - global_position.x)
		# Se player estiver exatamente na mesma posição X, manter direção atual
		if player_dir != 0:
			direction_x = player_dir
		animated_sprite.flip_h = direction_x > 0  # Invertido para o minotaur
		
		# Atualizar posição do AttackArea durante o ataque
		if direction_x > 0:
			attack_area.position.x = 100
		else:
			attack_area.position.x = -100

	# Aplicar movimento durante o ataque
	attack_elapsed += _delta
	if attack_elapsed <= ATTACK_LUNGE_TIME:
		velocity.x = direction_x * (SPEED * ATTACK_LUNGE_MULT)
	else:
		velocity.x = direction_x * (SPEED * ATTACK_DRIFT_MULT)

	# Garantir que a animação de ataque está tocando
	if animated_sprite.animation != "attack":
		animated_sprite.play("attack")


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return

	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
			has_damaged_this_attack = true
			print("Minotaur acertou o player!")

func _check_overlapping_bodies_in_attack_area():
	# Verificar corpos sobrepostos no AttackArea durante o ataque
	if not is_attacking or not attack_area.monitoring or has_damaged_this_attack:
		return
	
	var bodies = attack_area.get_overlapping_bodies()
	print("AttackArea overlapping bodies: ", bodies.size())
	for body in bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(ATTACK_DAMAGE)
				has_damaged_this_attack = true
				print("Minotaur acertou o player (overlap check)! Player pos: ", body.global_position, " Minotaur pos: ", global_position)
				return


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_node = body
		# Mudar para CHASE imediatamente quando detectar (exceto se estiver morto)
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
	attack_area.monitoring = false
	attack_area.position.x = 0  # Resetar posição do AttackArea
	
	# Voltar para o estado apropriado
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
			attack_area.monitoring = false
			attack_area.position.x = 0  # Resetar posição do AttackArea


func die():
	current_state = State.DEAD
	is_dead = true
	velocity = Vector2.ZERO
	# Desabilitar áreas de detecção e ataque
	detection_area.monitoring = false
	attack_area.monitoring = false
	animated_sprite.play("idle")  # Minotaur não tem animação death, usar idle
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
	if players.size() == 0:
		return
		
	var player = players[0]
	if not is_instance_valid(player):
		return
	
	# Calcular distância horizontal e vertical separadamente
	var horizontal_dist = abs(global_position.x - player.global_position.x)
	var vertical_dist = player.global_position.y - global_position.y  # Positivo se player está abaixo
	
	# Verificar se o player está à frente do minotaur
	var player_dir = sign(player.global_position.x - global_position.x)
	var is_in_front = (player_dir == direction_x) or (horizontal_dist < 50)  # Se muito perto, considerar à frente
	
	# Detecção melhorada - player está na altura das pernas (próximo ao chão)
	# Range horizontal de 500 pixels e player pode estar até 80 pixels abaixo ou 80 acima
	# Isso cobre a área das pernas do minotaur
	if horizontal_dist < 500 and vertical_dist >= -80 and vertical_dist < 80 and is_in_front:
		# Se o player está dentro do range e à frente, detectar
		player_node = player
		# Mudar para CHASE se estiver em PATROL
		if current_state == State.PATROL:
			current_state = State.CHASE
			print("Minotaur detectou player manualmente! Dist: ", horizontal_dist, " Vertical: ", vertical_dist, " Direção: ", player_dir)


func _start_attack_window():
	# Posicionar AttackArea à frente do minotaur baseado na direção
	if direction_x > 0:
		attack_area.position.x = 100  # À frente quando olhando para direita
	else:
		attack_area.position.x = -100  # À frente quando olhando para esquerda
	
	# Ativar hit apenas durante a janela ativa, após windup
	var windup_timer = get_tree().create_timer(ATTACK_WINDUP)
	windup_timer.timeout.connect(func():
		# Verificar se ainda está atacando antes de ativar o hitbox
		if not is_attacking or current_state != State.ATTACK:
			return
		
		attack_area.monitoring = true
		
		# Checagem imediata para casos já sobrepostos (múltiplas tentativas)
		call_deferred("_check_overlapping_bodies_in_attack_area")
		get_tree().create_timer(0.01).timeout.connect(_check_overlapping_bodies_in_attack_area)
		get_tree().create_timer(0.03).timeout.connect(_check_overlapping_bodies_in_attack_area)
		get_tree().create_timer(0.05).timeout.connect(_check_overlapping_bodies_in_attack_area)
		get_tree().create_timer(0.08).timeout.connect(_check_overlapping_bodies_in_attack_area)
		get_tree().create_timer(0.1).timeout.connect(_check_overlapping_bodies_in_attack_area)
		
		# Tempo ativo - janela de dano
		var active_timer = get_tree().create_timer(ATTACK_ACTIVE)
		active_timer.timeout.connect(func():
			attack_area.monitoring = false
		)
	)


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
	animated_sprite.play("walk")


func _on_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

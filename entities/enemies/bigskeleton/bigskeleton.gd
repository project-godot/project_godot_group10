extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var attack_timer = $Timer

const SPEED = 60.0
const ATTACK_RANGE = 50.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 5
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 6

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
var last_hit_time: float = 0.0
var current_hit_window: int = 0  # 0 = nenhum, 1 = primeiro hit, 2 = segundo hit
const HIT_COOLDOWN = 0.15  # Cooldown entre hits para evitar dano excessivo
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.5
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_COOLDOWN = 0.5
const ATTACK_WINDUP_1 = 0.3  # Primeiro hit - quando a espada vai para frente (após ~20% da animação)
const ATTACK_ACTIVE_1 = 0.12  # Janela curta para o primeiro hit
const ATTACK_WINDUP_2 = 0.7  # Segundo hit - quando a espada volta (após ~47% da animação)
const ATTACK_ACTIVE_2 = 0.12  # Janela curta para o segundo hit

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
		animated_sprite.flip_h = direction_x < 0

func _check_initial_overlap():
	# Verificar se há corpos já sobrepostos na DetectionArea quando o inimigo spawna
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			player_node = body
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

	# Reaquisição manual do player apenas se não tiver player_node
	if player_node == null or not is_instance_valid(player_node):
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

	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED

func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)

		# Se o player sair do range, voltar para patrulha
		if dist > 350:
			current_state = State.PATROL
			player_node = null
			return

		# Se estiver perto o suficiente e não estiver atacando, atacar
		if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			current_state = State.ATTACK
			is_attacking = true
			has_damaged_this_attack = false
			attack_elapsed = 0.0
			last_hit_time = 0.0  # Resetar cooldown de hits
			current_hit_window = 0  # Resetar janela de hit atual
			attack_cooldown_timer = ATTACK_COOLDOWN
			
			# Definir duração do timer baseado no ataque
			# A animação tem ~1.5 segundos (15 frames / speed 10.0)
			var attack_duration = 1.5
			attack_timer.start(attack_duration)
			
			# Iniciar a animação imediatamente
			animated_sprite.play("attack")
			_start_attack_window()
			return

		# Perseguir o player
		direction_x = sign(player_node.global_position.x - global_position.x)
		animated_sprite.flip_h = direction_x < 0
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		current_state = State.PATROL


func attack_state(_delta):
	# Recalcular direção em relação ao player
	if player_node and is_instance_valid(player_node):
		direction_x = sign(player_node.global_position.x - global_position.x)
		animated_sprite.flip_h = direction_x < 0
		
		# Atualizar posição da área de ataque baseada na direção
		if attack_area:
			attack_area.position.x = 80 if direction_x > 0 else -80
			attack_area.position.y = 0

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

	# Permitir múltiplos hits durante o ataque com cooldown entre hits
	if body.is_in_group("player") and is_attacking and attack_area.monitoring:
		if body.has_method("take_damage"):
			var current_time = Time.get_ticks_msec() / 1000.0
			# Verificar cooldown entre hits (reduzido para garantir que ambos os hits funcionem)
			if current_time - last_hit_time >= HIT_COOLDOWN:
				body.take_damage(1.0)  # Half a heart damage (1 health point)
				last_hit_time = current_time
				# Também fazer checagem imediata para garantir que o hit foi aplicado
				call_deferred("_check_overlapping_bodies_immediate")


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_node = body
		# Mudar para CHASE imediatamente quando detectar (exceto se estiver morto)
		if current_state != State.DEAD:
			current_state = State.CHASE


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
		# Tocar animação de hit
		animated_sprite.play("hit")
		# Interromper ataque se estiver atacando
		if is_attacking:
			is_attacking = false
			attack_area.monitoring = false


func die():
	current_state = State.DEAD
	is_dead = true
	velocity = Vector2.ZERO
	# Desabilitar áreas de detecção e ataque
	detection_area.monitoring = false
	attack_area.monitoring = false
	
	# Drop coins immediately
	_drop_coins()
	
	# Play death animation and disappear quickly
	animated_sprite.play("death")
	var death_timer = get_tree().create_timer(0.3)
	death_timer.timeout.connect(_on_death_complete)


func _on_death_complete():
	queue_free()


func _drop_coins():
	var coin_scene = preload("res://assets/items/coin.tscn")
	for i in range(COIN_DROP_COUNT):
		var coin = coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)
		
		# Better coin distribution - circular pattern with random spread
		var angle = (i * 2.0 * PI / COIN_DROP_COUNT) + randf_range(-0.3, 0.3)
		var radius = randf_range(15, 35)
		var offset_x = cos(angle) * radius
		var offset_y = sin(angle) * radius - 10  # Slight upward bias
		
		coin.global_position = global_position + Vector2(offset_x, offset_y)
		
		# Add initial velocity to spread coins out
		if coin.has_method("_apply_initial_velocity"):
			var vel_x = cos(angle) * randf_range(50, 150)
			var vel_y = sin(angle) * randf_range(50, 150) - 50  # Upward bias
			coin._apply_initial_velocity(Vector2(vel_x, vel_y))


func check_for_player_manually():
	# Se já tem player_node válido, não precisa verificar novamente
	if player_node != null and is_instance_valid(player_node):
		return
		
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if not is_instance_valid(player):
			return
			
		var distance = global_position.distance_to(player.global_position)
		# Range de detecção manual de 300 pixels
		if distance < 300:
			# Se o player está dentro do range, detectar independente da direção
			player_node = player
			# Só mudar estado se ainda estiver em PATROL
			if current_state == State.PATROL:
				current_state = State.CHASE


func _start_attack_window():
	# Posicionar área de ataque baseada na direção inicial
	if attack_area and player_node and is_instance_valid(player_node):
		var player_dir = sign(player_node.global_position.x - global_position.x)
		attack_area.position.x = 80 if player_dir > 0 else -80
		attack_area.position.y = 0
	
	# Primeiro hit - quando a espada vai para frente
	await get_tree().create_timer(ATTACK_WINDUP_1).timeout
	
	if not is_attacking or current_state != State.ATTACK:
		return
	
	if attack_area:
		attack_area.monitoring = true
		# Atualizar posição caso a direção tenha mudado
		if player_node and is_instance_valid(player_node):
			var player_dir = sign(player_node.global_position.x - global_position.x)
			attack_area.position.x = 80 if player_dir > 0 else -80
			attack_area.position.y = 0
	
	current_hit_window = 1  # Marcar que estamos no primeiro hit
	
	# Checagem imediata para o primeiro hit
	_check_overlapping_bodies_immediate()
	call_deferred("_check_overlapping_bodies_immediate")
	
	# Checagem periódica durante a janela do primeiro hit
	var check_interval = 0.02  # Verificar a cada 20ms
	var checks_count = int(ATTACK_ACTIVE_1 / check_interval)
	for i in range(checks_count):
		await get_tree().create_timer(check_interval).timeout
		if is_attacking and attack_area and attack_area.monitoring:
			_check_overlapping_bodies_immediate()
	
	# Desativar após a janela do primeiro hit
	if attack_area:
		attack_area.monitoring = false
	
	# Segundo hit - quando a espada volta
	await get_tree().create_timer(ATTACK_WINDUP_2 - ATTACK_WINDUP_1 - ATTACK_ACTIVE_1).timeout
	
	if not is_attacking or current_state != State.ATTACK:
		return
	
	if attack_area:
		attack_area.monitoring = true
		# Atualizar posição caso a direção tenha mudado
		if player_node and is_instance_valid(player_node):
			var player_dir = sign(player_node.global_position.x - global_position.x)
			attack_area.position.x = 80 if player_dir > 0 else -80
			attack_area.position.y = 0
	
	current_hit_window = 2  # Marcar que estamos no segundo hit
	# Resetar last_hit_time para permitir o segundo hit
	last_hit_time = Time.get_ticks_msec() / 1000.0 - HIT_COOLDOWN - 0.1
	
	# Checagem imediata para o segundo hit
	_check_overlapping_bodies_immediate()
	call_deferred("_check_overlapping_bodies_immediate")
	
	# Checagem periódica durante a janela do segundo hit
	var check_interval_2 = 0.02  # Verificar a cada 20ms
	var checks_count_2 = int(ATTACK_ACTIVE_2 / check_interval_2)
	for i in range(checks_count_2):
		await get_tree().create_timer(check_interval_2).timeout
		if is_attacking and attack_area and attack_area.monitoring:
			_check_overlapping_bodies_immediate()
	
	# Desativar após a janela do segundo hit
	if attack_area:
		attack_area.monitoring = false

func _check_overlapping_bodies_immediate():
	# Checagem de corpos já sobrepostos quando o hitbox é ativado
	if not is_attacking or not attack_area or not attack_area.monitoring:
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var bodies = attack_area.get_overlapping_bodies()
	for b in bodies:
		if b and b.is_in_group("player") and b.has_method("take_damage"):
			# Verificar cooldown entre hits
			# Para o segundo hit, garantir que pode aplicar mesmo se o primeiro hit foi recente
			var can_apply_hit = false
			if current_hit_window == 2:
				# Segundo hit sempre pode aplicar (cooldown já foi resetado)
				can_apply_hit = true
			else:
				# Primeiro hit verifica cooldown normal
				can_apply_hit = (current_time - last_hit_time >= HIT_COOLDOWN)
			
			if can_apply_hit:
				b.take_damage(1.0)  # Half a heart damage (1 health point)
				last_hit_time = current_time
				print("Bigskeleton hit player in window ", current_hit_window)
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
	animated_sprite.play("walk")


func _on_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

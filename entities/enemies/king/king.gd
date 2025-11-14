extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $RayCast2D
@onready var attack_timer = $Timer
@onready var healthbar = $CanvasLayer/Healthbar
@onready var king_label = $CanvasLayer/Label

const SPEED = 80.0
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 30  # Significantly more health than minotaur (20)
const ATTACK_DAMAGE = 3  # More damage than before (was 2)
const COIN_DROP_COUNT = 10
const HEALTHBAR_PROXIMITY_DISTANCE = 300.0

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
const ATTACK_COOLDOWN = 0.1  # Extremely fast attack cooldown for difficult boss
var hurt_lock_timer: float = 0.0
var has_damaged_this_attack: bool = false
var combo_hit_count: int = 0  # Contador de hits do combo
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.6
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_WINDUP_GROUND = 0.5  # Very fast windup for ground_attack (was 0.8)
const ATTACK_WINDUP_COMBO_HIT1 = 0.2   # Very fast first combo hit (was 0.3)
const ATTACK_WINDUP_COMBO_HIT2 = 0.5   # Very fast second combo hit (was 0.8)
const ATTACK_ACTIVE = 0.2  # Tempo que o hitbox fica ativo
var current_attack_animation: String = ""
var last_attack_type: String = ""  # Para intercalar os ataques

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

	# Inicializar healthbar
	if healthbar:
		healthbar.init_health(MAX_HEALTH)
		healthbar.health = health
		healthbar.visible = false  # Começar invisível
	
	# Inicializar label
	if king_label:
		king_label.visible = false  # Começar invisível

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
	
	# Atualizar visibilidade da healthbar baseado na proximidade do player
	_update_healthbar_visibility()

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
	ledge_check.position.x = 17 * direction_x
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1

	# Verificar se há chão à frente antes de continuar
	if is_on_floor() and ledge_check.enabled:
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
			return

		# Se estiver perto o suficiente e não estiver atacando, atacar
		if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			current_state = State.ATTACK
			is_attacking = true
			has_damaged_this_attack = false
			combo_hit_count = 0  # Resetar contador de hits do combo
			attack_elapsed = 0.0
			attack_cooldown_timer = ATTACK_COOLDOWN
			
			# Intercalar entre os dois ataques
			if last_attack_type == "ground_attack":
				current_attack_animation = "combo"
				last_attack_type = "combo"
				attack_timer.start(2.0)  # Duração do combo mais rápida: 55 frames / 30 fps = 1.83s + buffer
			elif last_attack_type == "combo":
				current_attack_animation = "ground_attack"
				last_attack_type = "ground_attack"
				attack_timer.start(2.3)  # Duração do ground_attack mais rápida: 32 frames / 15 fps = 2.13s + buffer
			else:
				# Primeiro ataque, começar com ground_attack
				current_attack_animation = "ground_attack"
				last_attack_type = "ground_attack"
				attack_timer.start(2.3)  # Duração do ground_attack mais rápida: 32 frames / 15 fps = 2.13s + buffer
			
			# Iniciar a animação imediatamente
			animated_sprite.play(current_attack_animation)
			_start_attack_window()
			return

		# Perseguir o player
		direction_x = sign(player_node.global_position.x - global_position.x)
		ledge_check.position.x = 17 * direction_x
		# Verificar se há chão à frente antes de continuar
		if is_on_floor() and ledge_check.enabled:
			ledge_check.force_raycast_update()
			if not ledge_check.is_colliding():
				# Não há chão à frente, não mover nessa direção
				velocity.x = 0
				animated_sprite.flip_h = direction_x < 0
				animated_sprite.play("walk")
				return
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


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return

	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(float(ATTACK_DAMAGE))  # Use ATTACK_DAMAGE constant
			has_damaged_this_attack = true


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
	
	# Atualizar healthbar
	if healthbar:
		healthbar.health = health

	if health <= 0:
		die()
	else:
		levando_hit = true
		hurt_lock_timer = 0.25
		# Efeito visual de dano (flash vermelho)
		_start_hurt_effect()


func die():
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
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
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if global_position.distance_to(player.global_position) < 220:
			player_node = player
			current_state = State.CHASE


func _start_attack_window():
	if current_attack_animation == "ground_attack":
		# Ground_attack: um único hit quando bate no chão
		var windup_timer = get_tree().create_timer(ATTACK_WINDUP_GROUND)
		windup_timer.timeout.connect(func():
			if not is_attacking or current_attack_animation != "ground_attack":
				return
			_activate_hitbox()
		)
	elif current_attack_animation == "combo":
		# Combo: dois hits - primeiro e segundo martelo
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
	attack_area.monitoring = true
	# Checagem imediata para casos já sobrepostos
	if not has_damaged_this_attack and is_attacking:
		var bodies = attack_area.get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("player") and b.has_method("take_damage"):
				b.take_damage(ATTACK_DAMAGE)
				has_damaged_this_attack = true
				break
	# Tempo ativo - janela de dano
	var active_timer = get_tree().create_timer(ATTACK_ACTIVE)
	active_timer.timeout.connect(func():
		attack_area.monitoring = false
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
	last_attack_type = ""
	animated_sprite.play("walk")


func _on_animation_finished(anim_name):
	if anim_name == "death":
		queue_free()

func _update_healthbar_visibility():
	if not healthbar:
		return
	
	# Verificar se há player próximo
	var players = get_tree().get_nodes_in_group("player")
	var should_show = false
	if players.size() > 0:
		var player = players[0]
		var distance = global_position.distance_to(player.global_position)
		
		# Mostrar healthbar se o player estiver próximo
		if distance <= HEALTHBAR_PROXIMITY_DISTANCE:
			should_show = true
	
	# Atualizar visibilidade do healthbar e label
	healthbar.visible = should_show
	if king_label:
		king_label.visible = should_show

func _start_hurt_effect():
	# Efeito visual de dano - flash vermelho
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)


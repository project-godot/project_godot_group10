extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $LedgeCheck
@onready var attack_timer = $AttackTimer
@onready var collision: CollisionShape2D = $AttackArea/Collision

const SPEED = 50.0
const VIDA_MAX = 5
const DANO = 1
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 50.0
const MAX_HEALTH = 2
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 5

var vida: int = VIDA_MAX
var is_dead: bool = false
var levando_hit: bool = false
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
const ATTACK_COOLDOWN = 1.0
var player_last_position_y = 0.0
var hurt_lock_timer: float = 0.0
var has_damaged_this_attack: bool = false
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.6
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_WINDUP = 0.12
const ATTACK_ACTIVE = 0.18

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

	# ⬇️ Conectar animações
	animated_sprite.animation_finished.connect(_on_animation_finished)

	# Garantir raycast de beirada ativo
	ledge_check.enabled = true

	# Desabilitar hitbox de ataque fora da janela ativa
	attack_area.monitoring = false

	call_deferred("_connect_to_player")


func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Travar comportamento enquanto leva dano para não sobrescrever animação de hurt
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

	# Reaquisição manual do player (ambos os estados)
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
	ledge_check.position.x = 17 * direction_x
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1

	if is_on_floor() and not ledge_check.is_colliding():
		direction_x *= -1

	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED


func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)

		if dist > 300:
			current_state = State.PATROL
			return

		if dist < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			current_state = State.ATTACK
			is_attacking = true
			has_damaged_this_attack = false
			attack_elapsed = 0.0
			attack_cooldown_timer = ATTACK_COOLDOWN
			attack_timer.start()
			_start_attack_window()
			return

		direction_x = sign(player_node.global_position.x - global_position.x)
		ledge_check.position.x = 17 * direction_x
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

	# Aplicar movimento durante o ataque (lunge curto + drift leve)
	attack_elapsed += _delta
	if attack_elapsed <= ATTACK_LUNGE_TIME:
		velocity.x = direction_x * (SPEED * ATTACK_LUNGE_MULT)
	else:
		velocity.x = direction_x * (SPEED * ATTACK_DRIFT_MULT)

	animated_sprite.play("attack")


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return

	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(1.0)  # Half a heart damage (1 health point)
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


func _on_attack_timer_timeout():
	is_attacking = false
	has_damaged_this_attack = false
	current_state = State.CHASE if player_node != null else State.PATROL

	# Encerrar janela de ataque caso ainda ativa
	attack_area.monitoring = false


func take_damage(damage: int):
	if current_state == State.DEAD:
		return

	health -= damage

	if health <= 0:
		die()
	else:
		levando_hit = true
		hurt_lock_timer = 0.25
		animated_sprite.play("hurt")


func die():
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	# Drop coins immediately
	_drop_coins()
	
	# Play death animation and disappear quickly
	animated_sprite.play("die")
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
	# Ativar hit apenas durante a janela ativa, após windup
	var windup_timer = get_tree().create_timer(ATTACK_WINDUP)
	windup_timer.timeout.connect(func():
		attack_area.monitoring = true
		# Checagem imediata para casos já sobrepostos
		if not has_damaged_this_attack and is_attacking:
			var bodies = attack_area.get_overlapping_bodies()
			for b in bodies:
				if b.is_in_group("player") and b.has_method("take_damage"):
					b.take_damage(ATTACK_DAMAGE)
					has_damaged_this_attack = true
					break
		# Tempo ativo
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
	animated_sprite.play("idle")


# ✅ NOVA FUNÇÃO ADICIONADA
func _on_animation_finished(anim_name):
	if is_dead:
		queue_free()
	if anim_name == "attack":
		is_attacking = false

extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea2
@onready var attack_area = $AttackArea2
@onready var ledge_check = $LedgeCheck2
@onready var attack_timer = $AttackTimer2

const SPEED = 45.0
const GRAVITY = 900.0
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 80.0
const ATTACK_COOLDOWN = 1.0
const MAX_HEALTH = 3
const ATTACK_DAMAGE = 1

var direction_x := 1
var current_state := State.PATROL
var player_node = null
var is_attacking := false
var attack_cooldown_timer := 0.0
var start_position : Vector2
var left_limit : float
var right_limit : float
var health := MAX_HEALTH

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	animated_sprite.play("walk")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.CHASE:
			chase_state(delta)
		State.ATTACK:
			attack_state(delta)

	move_and_slide()

func patrol_state(delta):
	velocity.x = direction_x * SPEED
	animated_sprite.play("walk")
	animated_sprite.flip_h = direction_x < 0

	# inverter direção ao chegar nos limites ou beirada
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1
	elif is_on_floor() and ledge_check and not ledge_check.is_colliding():
		direction_x *= -1

func chase_state(delta):
	if not player_node or not is_instance_valid(player_node):
		current_state = State.PATROL
		return

	var distance = position.distance_to(player_node.position)

	if distance > 300:
		print("👁️ Jogador fora de alcance, voltando a patrulhar.")
		current_state = State.PATROL
		player_node = null
		return

	if distance < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
		print("⚔️ Ataque iniciado no jogador!")
		if player_node.has_method("take_damage"):
			player_node.take_damage(ATTACK_DAMAGE)
		is_attacking = true
		current_state = State.ATTACK
		attack_cooldown_timer = ATTACK_COOLDOWN
		attack_timer.start()
		return

	direction_x = sign(player_node.position.x - position.x)
	velocity.x = direction_x * SPEED
	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")

func attack_state(_delta):
	velocity.x = 0
	animated_sprite.play("attack")

func _on_detection_area_body_entered(body):
	print("🔍 DETECTOU algo:", body.name, " | grupos:", body.get_groups())
	if body.is_in_group("player"):
		print("✅ Jogador detectado! Mudando para CHASE")
		player_node = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == player_node:
		print("❌ Jogador saiu da detecção.")
		player_node = null
		current_state = State.PATROL
		is_attacking = false

func _on_attack_timer_timeout():
	is_attacking = false
	if player_node and is_instance_valid(player_node):
		var distance = position.distance_to(player_node.position)
		if distance < 200:
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	else:
		current_state = State.PATROL

func take_damage(damage: int):
	health -= damage
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

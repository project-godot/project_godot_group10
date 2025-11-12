extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $Timer
@onready var healthbar = $CanvasLayer/Healthbar

const SPEED = 70.0
const ATTACK_RANGE = 100.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 20
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 10
const DETECTION_RANGE = 500.0
const DETECTION_VERTICAL_TOLERANCE = 200.0

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

	if healthbar:
		healthbar.init_health(MAX_HEALTH)
		healthbar.health = health

	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	if attack_area:
		attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	if attack_timer:
		attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

	if animated_sprite:
		animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

	if attack_area:
		attack_area.monitoring = false

	if detection_area:
		detection_area.monitoring = true
		detection_area.monitorable = true

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
	if not player_node or not is_instance_valid(player_node):
		current_state = State.PATROL
		return

	var minotaur_center = global_position + Vector2(0, 20)
	var player_center = player_node.global_position
	var dist = minotaur_center.distance_to(player_center)

	if dist > DETECTION_RANGE:
		current_state = State.PATROL
		player_node = null
		return

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

	var player_dir = sign(player_center.x - minotaur_center.x)
	if player_dir != 0:
		direction_x = player_dir

	if animated_sprite:
		animated_sprite.flip_h = direction_x > 0
		animated_sprite.play("walk")

	velocity.x = direction_x * SPEED


func attack_state(_delta):
	if player_node and is_instance_valid(player_node):
		var minotaur_center = global_position + Vector2(0, 20)
		var player_center = player_node.global_position
		var player_dir = sign(player_center.x - minotaur_center.x)
		if player_dir != 0:
			direction_x = player_dir

		if animated_sprite:
			animated_sprite.flip_h = direction_x > 0

		if attack_area:
			attack_area.position.x = 125 if direction_x > 0 else -125
			attack_area.position.y = 0

	attack_elapsed += _delta
	if attack_elapsed <= ATTACK_LUNGE_TIME:
		velocity.x = direction_x * (SPEED * ATTACK_LUNGE_MULT)
	else:
		velocity.x = direction_x * (SPEED * ATTACK_DRIFT_MULT)

	if animated_sprite and animated_sprite.animation != "attack":
		animated_sprite.play("attack")


func _on_attack_area_body_entered(body):
	if current_state == State.DEAD:
		return
	if not body:
		return
	if body.is_in_group("player") and is_attacking and not has_damaged_this_attack:
		if body.has_method("take_damage"):
			body.take_damage(0.5)
			has_damaged_this_attack = true


func _check_overlapping_bodies_in_attack_area():
	if not is_attacking or not attack_area or not attack_area.monitoring or has_damaged_this_attack:
		return

	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body and body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(0.5)
				has_damaged_this_attack = true
				return


func _on_detection_area_body_entered(body):
	if not body:
		return
	if body.is_in_group("player"):
		player_node = body
		if current_state != State.DEAD:
			current_state = State.CHASE


func _on_detection_area_body_exited(body):
	if body == player_node:
		pass


func _on_attack_timer_timeout():
	is_attacking = false
	has_damaged_this_attack = false
	if attack_area:
		attack_area.monitoring = false
		attack_area.position = Vector2.ZERO

	if player_node != null and is_instance_valid(player_node):
		current_state = State.CHASE
	else:
		current_state = State.PATROL


func take_damage(damage: int):
	if current_state == State.DEAD or is_dead:
		return

	health -= damage
	healthbar.health = health

	if health <= 0:
		die()
	else:
		levando_hit = true
		hurt_lock_timer = 0.25

		if is_attacking:
			is_attacking = false
			if attack_area:
				attack_area.monitoring = false
				attack_area.position = Vector2.ZERO


func die():
	current_state = State.DEAD
	is_dead = true
	velocity = Vector2.ZERO
	if detection_area:
		detection_area.monitoring = false
	if attack_area:
		attack_area.monitoring = false

	_drop_coins()

	if animated_sprite:
		animated_sprite.play("idle")
	var death_timer = get_tree().create_timer(0.2)
	death_timer.timeout.connect(Callable(self, "_on_death_complete"))


func _on_death_complete():
	queue_free()


func _drop_coins():
	var coin_scene = preload("res://assets/items/coin.tscn")
	for i in range(COIN_DROP_COUNT):
		var coin = coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)

		var angle = (i * 2.0 * PI / COIN_DROP_COUNT) + randf_range(-0.3, 0.3)
		var radius = randf_range(15, 35)
		var offset_x = cos(angle) * radius
		var offset_y = sin(angle) * radius - 10
		
		coin.global_position = global_position + Vector2(offset_x, offset_y)
		
		if coin.has_method("_apply_initial_velocity"):
			var vel_x = cos(angle) * randf_range(50, 150)
			var vel_y = sin(angle) * randf_range(50, 150) - 50
			coin._apply_initial_velocity(Vector2(vel_x, vel_y))


func check_for_player_manually():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		if current_state == State.CHASE or current_state == State.ATTACK:
			player_node = null
			if current_state != State.ATTACK:
				current_state = State.PATROL
		return

	var player = players[0]
	if not is_instance_valid(player):
		return

	var minotaur_center = global_position + Vector2(0, 20)
	var player_center = player.global_position
	
	var horizontal_dist = abs(minotaur_center.x - player_center.x)
	var vertical_dist = abs(minotaur_center.y - player_center.y)
	var total_dist = minotaur_center.distance_to(player_center)

	if total_dist > DETECTION_RANGE:
		if player_node == player and (current_state == State.CHASE or current_state == State.ATTACK):
			player_node = null
			if current_state != State.ATTACK:
				current_state = State.PATROL
		return

	if vertical_dist > DETECTION_VERTICAL_TOLERANCE:
		return

	var player_dir = sign(player_center.x - minotaur_center.x)
	var is_in_front = false
	
	if player_dir == direction_x:
		is_in_front = true
	elif horizontal_dist < 120:
		is_in_front = true
	elif current_state == State.PATROL:
		is_in_front = true

	if is_in_front:
		player_node = player
		if current_state == State.PATROL:
			current_state = State.CHASE


func _start_attack_window() -> void:
	if attack_area:
		attack_area.position.x = 125 if direction_x > 0 else -125
		attack_area.position.y = 0

	await get_tree().create_timer(ATTACK_WINDUP).timeout

	if not is_attacking or current_state != State.ATTACK:
		if attack_area:
			attack_area.monitoring = false
			attack_area.position = Vector2.ZERO
		return

	if attack_area:
		attack_area.monitoring = true

	call_deferred("_check_overlapping_bodies_in_attack_area")
	await get_tree().create_timer(0.01).timeout
	call_deferred("_check_overlapping_bodies_in_attack_area")
	await get_tree().create_timer(0.02).timeout
	call_deferred("_check_overlapping_bodies_in_attack_area")

	await get_tree().create_timer(ATTACK_ACTIVE).timeout

	if attack_area:
		attack_area.monitoring = false
		attack_area.position = Vector2.ZERO


func _connect_to_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player and player.has_signal("player_left_screen"):
			player.connect("player_left_screen", Callable(self, "_on_player_left_screen"))
	else:
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

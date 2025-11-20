extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $Timer
@onready var healthbar = $CanvasLayer/Healthbar
@onready var ledge_check = $RayCast2D if has_node("RayCast2D") else null

const SPEED = 70.0
const ATTACK_RANGE = 100.0
const PATROL_DISTANCE = 100.0
const MAX_HEALTH = 20
const ATTACK_DAMAGE = 2
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
var attack_swing_count: int = 0  # Track which swing we're on (0 = first/forward, 1 = second/backward)
var last_attack_frame: int = -1  # Track last frame to detect frame changes
const ATTACK_LUNGE_TIME = 0.15
const ATTACK_LUNGE_MULT = 1.5
const ATTACK_DRIFT_MULT = 0.2
var attack_elapsed: float = 0.0
const ATTACK_COOLDOWN = 0.4
const ATTACK_WINDUP = 0.3
const ATTACK_ACTIVE = 0.2
var death_animation_finished: bool = false

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

	# Configurar raycast se existir
	if ledge_check:
		ledge_check.enabled = true
		ledge_check.target_position = Vector2(0, 38)
	
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

	# Verificar se há chão à frente usando raycast
	if ledge_check and ledge_check.enabled:
		ledge_check.position.x = 17 * direction_x
		if is_on_floor():
			ledge_check.force_raycast_update()
			if not ledge_check.is_colliding():
				direction_x *= -1
				ledge_check.position.x = 17 * direction_x

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
		attack_swing_count = 0
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

	# Verificar se há chão à frente antes de continuar
	if ledge_check and ledge_check.enabled:
		ledge_check.position.x = 17 * direction_x
		if is_on_floor():
			ledge_check.force_raycast_update()
			if not ledge_check.is_colliding():
				# Não há chão à frente, não mover nessa direção
				velocity.x = 0
				if animated_sprite:
					animated_sprite.flip_h = direction_x > 0
					animated_sprite.play("walk")
				return
	# Fallback: usar wall detection se não tiver raycast
	elif is_on_wall():
		velocity.x = 0
		if animated_sprite:
			animated_sprite.flip_h = direction_x > 0
			animated_sprite.play("walk")
		return

	if animated_sprite:
		animated_sprite.flip_h = direction_x > 0
		animated_sprite.play("walk")

	velocity.x = direction_x * SPEED


func attack_state(_delta):
	if current_state == State.DEAD or is_dead:
		return
	if player_node and is_instance_valid(player_node):
		var minotaur_center = global_position + Vector2(0, 20)
		var player_center = player_node.global_position
		var player_dir = sign(player_center.x - minotaur_center.x)
		if player_dir != 0:
			direction_x = player_dir

		if animated_sprite:
			animated_sprite.flip_h = direction_x > 0

		if attack_area:
			# Position attack area based on which swing we're on
			# First swing (forward): in front, second swing (backward): behind
			if attack_swing_count == 0:
				attack_area.position.x = 125 if direction_x > 0 else -125
			else:
				attack_area.position.x = -125 if direction_x > 0 else 125
			attack_area.position.y = 0

	# Track animation frame to detect when we're in each attack
	if animated_sprite and animated_sprite.animation == "attack":
		var current_frame = animated_sprite.frame
		var sprite_frames = animated_sprite.sprite_frames
		if sprite_frames:
			var frame_count = sprite_frames.get_frame_count("attack")
			if frame_count > 0:
				# Split animation in half: first half = first attack, second half = second attack
				var mid_frame = int(frame_count / 2)
				
				# Determine which attack we're currently in
				var new_swing_count = 0 if current_frame < mid_frame else 1
				
				# If we've moved into a new attack section, reset damage flag and update position
				if new_swing_count != attack_swing_count:
					attack_swing_count = new_swing_count
					has_damaged_this_attack = false  # Reset damage flag for new attack
					if attack_area:
						if attack_swing_count == 0:
							# First attack: position in front
							attack_area.position.x = 125 if direction_x > 0 else -125
						else:
							# Second attack: position behind
							attack_area.position.x = -125 if direction_x > 0 else 125
						attack_area.position.y = 0
				
				# Enable attack area during active frames of each attack
				# Active frames: middle portion of each half (30% to 70% of each half)
				var is_in_damage_frame = false
				if attack_swing_count == 0:
					# First attack active frames
					var first_half_start = 0
					var first_half_end = mid_frame
					var active_start = int(first_half_start + (first_half_end - first_half_start) * 0.3)
					var active_end = int(first_half_start + (first_half_end - first_half_start) * 0.7)
					is_in_damage_frame = (current_frame >= active_start and current_frame < active_end)
				else:
					# Second attack active frames
					var second_half_start = mid_frame
					var second_half_end = frame_count
					var active_start = int(second_half_start + (second_half_end - second_half_start) * 0.3)
					var active_end = int(second_half_start + (second_half_end - second_half_start) * 0.7)
					is_in_damage_frame = (current_frame >= active_start and current_frame < active_end)
				
				# Enable/disable attack area monitoring based on damage frames
				if attack_area:
					if is_in_damage_frame:
						if not attack_area.monitoring:
							attack_area.monitoring = true
						# Continuously check for overlapping bodies during damage frames
						call_deferred("_check_overlapping_bodies_in_attack_area")
					else:
						if attack_area.monitoring:
							attack_area.monitoring = false

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
			body.take_damage(1.0)  # Half a heart damage (1 health point)
			has_damaged_this_attack = true


func _check_overlapping_bodies_in_attack_area():
	if current_state == State.DEAD or is_dead:
		return
	if not is_attacking or not attack_area or not attack_area.monitoring:
		return
	
	# Don't check if we've already damaged this attack swing
	if has_damaged_this_attack:
		return

	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body and body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(1.0)  # Half a heart damage (1 health point)
				has_damaged_this_attack = true
				print("Minotaur attack ", attack_swing_count + 1, " hit player!")
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
	if current_state == State.DEAD or is_dead:
		return
	is_attacking = false
	has_damaged_this_attack = false
	attack_swing_count = 0
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
	
	# Parar qualquer ataque em andamento imediatamente
	is_attacking = false
	if attack_timer:
		attack_timer.stop()
	if attack_area:
		attack_area.monitoring = false
		attack_area.position = Vector2.ZERO
	if detection_area:
		detection_area.monitoring = false

	_drop_coins()

	if animated_sprite:
		animated_sprite.play("idle")
		var death_timer = get_tree().create_timer(0.2)
		death_timer.timeout.connect(Callable(self, "_on_death_complete"))
	
	# Após a morte, aguardar 3 segundos antes de mudar para o level3
	var transition_timer = get_tree().create_timer(3.0)
	transition_timer.timeout.connect(Callable(self, "_transition_to_level3"))
	
	# Não remover o nó imediatamente, pois a transição precisa acontecer primeiro
	# O nó será removido automaticamente quando a cena mudar


func _on_death_complete():
	# Tornar o minotauro invisível ao invés de removê-lo
	# Isso permite que o timer de transição continue funcionando
	if animated_sprite:
		animated_sprite.visible = false
	# Também esconder a healthbar se existir
	if healthbar:
		healthbar.visible = false
	# Desabilitar colisão
	if $CollisionShape2D:
		$CollisionShape2D.disabled = true


func _transition_to_level3():
	# Resetar moedas coletadas no nível atual
	GameManager.coins_collected = 0
	
	# Desbloquear o próximo nível
	if ManagerLevel:
		ManagerLevel.unlock_next_level()
	
	# Tentar encontrar o nó transition na cena atual
	var transition = get_tree().current_scene.get_node_or_null("transition")
	if transition and transition.has_method("_change_scene"):
		# Usar o transition se existir (com animação de fade)
		transition._change_scene("res://levels/level3.tscn")
	else:
		# Se não houver transition, fazer a mudança de cena diretamente
		get_tree().change_scene_to_file("res://levels/level3.tscn")


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
	# Initialize attack - frame-based detection in attack_state() will handle damage windows
	attack_swing_count = 0
	has_damaged_this_attack = false
	if attack_area:
		attack_area.position.x = 125 if direction_x > 0 else -125
		attack_area.position.y = 0
		attack_area.monitoring = false  # Will be enabled by frame detection


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
	# Marcar que a animação de morte terminou
	if anim_name == "death" and is_dead:
		death_animation_finished = true

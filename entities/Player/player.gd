extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_timer = $AttackTimer
@onready var attack_area = $Attack
@onready var camera = $Camera2D

@export var limite_y_morte: float = 1000.0

var is_attacking = false
var attacked_enemies = []  # Lista de inimigos já atacados neste ataque
const SPEED = 200.0
const JUMP_VELOCITY = -490.0
const GRAVITY = 980.0
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

# Sistema de vida
const MAX_HEALTH = 5
var health = MAX_HEALTH
var is_dead = false
var is_invincible = false
const INVINCIBILITY_TIME = 0.6
var invincibility_timer = 0.0
var is_hurt = false

# Janela do ataque (para sincronizar o acerto com a espada)
const ATTACK_WINDUP = 0.1
const ATTACK_ACTIVE = 0.18
const ATTACK_OFFSET_X = 20.0

# Sistema de respawn
var spawn_position: Vector2
var can_take_damage = true
var is_falling_off = false  # Flag para evitar múltiplas detecções de queda

signal health_changed(new_health: int)
signal player_died
signal player_respawned
signal player_left_screen  # Sinal quando o player sai da tela

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	# Conectar sinal de vida ao GameManager
	health_changed.connect(_on_health_changed)
	
	# Definir spawn inicial
	spawn_position = global_position

	# Desabilitar checagem de overlap do ataque fora da janela ativa
	attack_area.monitoring = false
	
	# Notificar GameManager sobre a vida inicial
	GameManager.player_health = health
	health_changed.emit(health)

func _physics_process(delta):
	if is_dead:
		return
	
	# Atualizar invencibilidade
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			can_take_damage = true
			modulate = Color.WHITE
	
	# Verificar se caiu do mapa
	_check_fell_off_map()
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jump_buffer_timer = 0.0
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0
	
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_attacking:
		animated_sprite.play("attack")
	elif is_hurt:
		animated_sprite.play("hurt")
	elif not is_on_floor():
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
		animated_sprite.play("jump")
	elif velocity.x > 0:
		animated_sprite.flip_h = false
		animated_sprite.play("run")
	elif velocity.x < 0:
		animated_sprite.flip_h = true
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
			
	move_and_slide()

func _unhandled_input(event):
	if is_dead:
		return
		
	if event.is_action_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			jump_buffer_timer = JUMP_BUFFER_TIME
	
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		attacked_enemies.clear()  # Limpar lista de inimigos atacados
		animated_sprite.play("attack")
		attack_timer.start()
		# Programar janela de acerto com windup + active
		_start_attack_window()
	
	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()

func _on_attack_timer_timeout():
	is_attacking = false
	attacked_enemies.clear()
	attack_area.monitoring = false

func _check_attack_area():
	# Verificar inimigos na área de ataque
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("enemies") and body not in attacked_enemies:
			if body.has_method("take_damage"):
				body.take_damage(1)
				attacked_enemies.append(body)  # Marcar como atacado

func _start_attack_window():
	# Posicionar hitbox da espada na frente do player
	if animated_sprite.flip_h:
		attack_area.position.x = -abs(ATTACK_OFFSET_X)
	else:
		attack_area.position.x = abs(ATTACK_OFFSET_X)

	# Esperar o windup antes de ativar o hitbox
	var windup_timer = get_tree().create_timer(ATTACK_WINDUP)
	windup_timer.timeout.connect(func():
		attack_area.monitoring = true
		# Checar imediatamente quem já está sobreposto
		_check_attack_area()

		# Ativar por tempo limitado (active frames)
		var active_timer = get_tree().create_timer(ATTACK_ACTIVE)
		active_timer.timeout.connect(func():
			attack_area.monitoring = false
		)
	)

func _on_attack_area_body_entered(body):
	# Verificar durante o ataque
	if is_attacking and body.is_in_group("enemies") and body not in attacked_enemies:
		if body.has_method("take_damage"):
			body.take_damage(1)
			attacked_enemies.append(body)

func _open_pause_menu():
	get_tree().paused = true
	var pause_menu = preload("res://levels/PauseMenu.tscn").instantiate()
	get_tree().current_scene.add_child(pause_menu)

func take_damage(damage: int):
	if not can_take_damage or is_invincible or is_dead:
		return
	
	health -= damage
	health = max(0, health)
	
	print("Jogador recebeu ", damage, " de dano! Vida restante: ", health)
	
	# Ativar invencibilidade
	is_invincible = true
	can_take_damage = false
	invincibility_timer = INVINCIBILITY_TIME
	
	# Efeito visual de invencibilidade (piscar)
	_start_invincibility_effect()
	
	# Animação de dano
	is_hurt = true
	animated_sprite.play("hurt")
	await get_tree().create_timer(0.3).timeout
	if not is_dead:
		is_hurt = false
	
	# Notificar mudança de vida
	health_changed.emit(health)
	GameManager.player_health = health
	
	if health <= 0:
		die()

func _start_invincibility_effect():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	await get_tree().create_timer(INVINCIBILITY_TIME)
	tween.kill()
	modulate = Color.WHITE

func die():
	if is_dead:
		return
	
	is_dead = true
	animated_sprite.play("death")
	player_died.emit()
	
	# Aguardar animação de morte
	await get_tree().create_timer(1.0).timeout
	
	# Reduzir vida (se ainda houver) e respawnar
	if health > 0: # Esta verificação já foi feita em take_damage, mas para garantir.
		# A vida já deve estar em 0 aqui se o player morreu.
		# Então, vamos apenas verificar se há vidas para respawnar.
		# Se o sistema de vidas extras for por GameManager, mantenha a lógica lá.
		# Se health > 0 após a morte, significa que tem mais de uma vida e a anterior já foi tirada
		# ao entrar na função die().
		pass # A vida já foi deduzida em take_damage()
	
	# Verifica se o jogador tem mais vidas para respawnar
	if GameManager.player_health > 0: # Assumindo que GameManager.player_health gerencia vidas totais
		respawn()
	else:
		# --- ALTERAÇÃO AQUI ---
		# Removi o GameManager.game_over.emit() daqui para evitar matar inimigos.
		# Você deve lidar com o "Game Over" de outra forma, como:
		# - Recarregar a cena atual: get_tree().reload_current_scene()
		# - Ir para uma tela de Game Over: get_tree().change_scene_to_file("res://menus/GameOverScreen.tscn")
		print("GAME OVER - Todas as vidas perdidas!")
		get_tree().reload_current_scene() # Exemplo: recarrega a cena atual
		# OU: get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")
		# ----------------------

func respawn():
	is_dead = false
	is_invincible = false
	can_take_damage = true
	is_falling_off = false  # Resetar flag de queda
	modulate = Color.WHITE
	
	# Reposicionar no spawn
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	# Notificar
	health_changed.emit(health)
	GameManager.player_health = health # Certifique-se que o GameManager reflete a vida correta
	player_respawned.emit()
	
	print("Player respawned! Vidas restantes: ", health)

func set_spawn_position(pos: Vector2):
	spawn_position = pos

func _check_fell_off_map():
	if is_dead or is_falling_off:
		return
	
	if global_position.y > limite_y_morte:
		is_falling_off = true  # Prevenir múltiplas detecções
		
		# Emitir sinal apenas quando o player REALMENTE cai (não quando respawna)
		player_left_screen.emit()
		
		# Reduzir vida do GameManager
		if GameManager.player_health > 0:
			GameManager.player_health -= 1
			health_changed.emit(GameManager.player_health)
		
		# Se ainda tem vidas globais, respawnar
		if GameManager.player_health > 0:
			# Reposicionar imediatamente no spawn
			global_position = spawn_position
			velocity = Vector2.ZERO
			is_dead = false  # Garantir que não está morto
			
			# Reiniciar a vida interna do player para MAX_HEALTH ao respawnar
			health = MAX_HEALTH
			
			is_invincible = true
			can_take_damage = true
			invincibility_timer = INVINCIBILITY_TIME
			modulate = Color.WHITE
			_start_invincibility_effect()
			is_falling_off = false  # Resetar flag após respawn
			print("Player caiu! Vidas restantes (GameManager): ", GameManager.player_health)
			player_respawned.emit() # Notificar o respawn
		else:
			# Sem vidas globais, chamar die() para Game Over
			is_falling_off = false  # Resetar flag antes de morrer
			die()

func _on_health_changed(new_health: int):
	GameManager.player_health = new_health # Garante que o GameManager esteja sempre atualizado
	# --- ALTERAÇÃO AQUI ---
	# Removi o GameManager.game_over.emit() daqui, pois 'die()' já cuida disso no final.
	# Isso evita que o sinal de game over seja emitido prematuramente ou em duplicidade.
	# ----------------------

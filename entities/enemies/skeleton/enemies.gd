extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $LedgeCheck
@onready var attack_timer = $AttackTimer

const SPEED = 50.0
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 50.0 
const MAX_HEALTH = 2
const ATTACK_DAMAGE = 1
const COIN_DROP_COUNT = 5  # Quantidade de coins que dropa ao morrer

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
const ATTACK_COOLDOWN = 1.0  # 2 segundos entre ataques
var player_last_position_y = 0.0  # Para rastrear a última posição Y do player

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE
	
	# Conectar sinais
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Conectar ao sinal do player quando ele sair da tela
	call_deferred("_connect_to_player")

func _physics_process(delta):
	# --- AJUSTE 1: PARAR NO VOID ---
	# Se estiver morto, não execute NADA (nem gravidade, nem move_and_slide)
	if current_state == State.DEAD:
		return
	# --- FIM DO AJUSTE 1 ---
	
	# Atualizar última posição Y do player para detectar respawn
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player:
			player_last_position_y = player.global_position.y
		
	if not is_on_floor():
		velocity.y += 980 * delta
	
	# Atualizar cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# Verificação manual de detecção do jogador (backup)
	if current_state == State.PATROL:
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
	if position.x <= left_limit:
		direction_x = 1
	elif position.x >= right_limit:
		direction_x = -1
	
	if is_on_floor() and not ledge_check.is_colliding():
		direction_x *= -1
			
	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	velocity.x = direction_x * SPEED
	
	# Debug: mostrar estado de patrulha
	if int(position.x) % 100 == 0:  # Print a cada 100 pixels
		print("PATRULHA - Posição: ", position.x, " - Limites: ", left_limit, " a ", right_limit)

func chase_state(_delta):
	if player_node and is_instance_valid(player_node):
		var distance_to_player = position.distance_to(player_node.position)
		
		# Se o jogador está muito longe OU caiu no limbo (posição Y muito alta), parar perseguição
		if distance_to_player > 300 or player_node.global_position.y > 900:
			current_state = State.PATROL
			player_node = null
			return
		
		# Se está no alcance de ataque e pode atacar
		if distance_to_player < ATTACK_RANGE and not is_attacking and attack_cooldown_timer <= 0:
			print("⚔️ Atacando jogador!")
			
			# Causar dano UMA VEZ
			if player_node.has_method("take_damage"):
				player_node.take_damage(ATTACK_DAMAGE)
				print("💥 ATAQUE EXECUTADO! Dano causado ao jogador")
			
			# Iniciar ataque
			current_state = State.ATTACK
			is_attacking = true
			attack_cooldown_timer = ATTACK_COOLDOWN
			attack_timer.start()
			return
		
		# Perseguir o jogador, mas verificar se há chão à frente antes
		var target_direction = sign(player_node.position.x - position.x)
		
		# Verificar se há chão à frente na direção que queremos ir
		# Se não houver chão à frente, não seguir (evitar cair no limbo)
		if is_on_floor():
			# Guardar posição original do LedgeCheck
			var original_position = ledge_check.position
			
			# Ajustar o LedgeCheck para verificar na direção do player
			if target_direction > 0:
				# Player está à direita, verificar chão à direita
				ledge_check.position = Vector2(abs(original_position.x), original_position.y)
			else:
				# Player está à esquerda, verificar chão à esquerda
				ledge_check.position = Vector2(-abs(original_position.x), original_position.y)
			
			# Atualizar o raycast para verificar colisão
			ledge_check.force_raycast_update()
			
			# Se não há chão à frente na direção do player, não seguir
			if not ledge_check.is_colliding():
				# Não há chão à frente, parar de perseguir e voltar para patrulha
				current_state = State.PATROL
				player_node = null
				# Restaurar posição original do LedgeCheck
				ledge_check.position = original_position
				return
			
			# Restaurar posição original do LedgeCheck após verificar
			ledge_check.position = original_position
		
		direction_x = target_direction
		animated_sprite.flip_h = direction_x < 0
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		current_state = State.PATROL
		animated_sprite.play("idle")

func attack_state(_delta):
	velocity.x = 0
	animated_sprite.play("attack")
	# O timer vai voltar para o estado de perseguição

func _on_detection_area_body_entered(body):
	if current_state == State.DEAD:
		return
	if body.is_in_group("enemies") or body.is_in_group("terrain") or body == self:
		return
	
	if body.is_in_group("player"):
		player_node = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if current_state == State.DEAD:
		return
		
	if body == player_node:
		player_node = null
		current_state = State.PATROL
		is_attacking = false

func _on_attack_timer_timeout():
	is_attacking = false
	
	if player_node and is_instance_valid(player_node):
		var distance_to_player = position.distance_to(player_node.position)
		if distance_to_player < 200:
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	else:
		current_state = State.PATROL

func take_damage(damage: int):
	if current_state == State.DEAD:
		return
		
	health -= damage
	print("Inimigo recebeu ", damage, " de dano. Vida restante: ", health)
	
	if health <= 0:
		die()
	else:
		animated_sprite.play("hurt")


# --- AJUSTE 2: FUNÇÃO 'die()' CORRIGIDA COM TIMER ---
func die():
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	
	# 1. PARAR TODO O MOVIMENTO (Resolve "cair no void")
	velocity = Vector2.ZERO
	
	# 2. Tocar a animação de morte
	animated_sprite.play("die")
	
	# 3. Desabilitar colisão
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	
	# 4. Desabilitar detecção
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	
	# 5. CRIAR UM TIMER (em vez de 'await')
	#    Reduzido para 0.6 segundos para ser mais rápido
	var death_timer = get_tree().create_timer(0.6)
	
	# 6. Conectar o timer a uma NOVA função que cuidará do drop e do queue_free
	death_timer.timeout.connect(_on_death_complete)


# --- FUNÇÃO ADICIONADA PARA O TIMER ---
# Esta função será chamada QUANDO O TIMER ACABAR
func _on_death_complete():
	# 7. AGORA, dropar os coins
	_drop_coins()
	
	# 8. E AGORA, remover o inimigo
	queue_free()
# --- FIM DO AJUSTE 2 ---


# --- AJUSTE 3: POSIÇÃO DE DROP DAS MOEDAS ---
func _drop_coins():
	# Instanciar coins
	var coin_scene = preload("res://assets/items/coin.tscn")
	
	for i in range(COIN_DROP_COUNT):
		var coin = coin_scene.instantiate()
		get_tree().current_scene.add_child(coin)

		# 'global_position' é o centro do inimigo.
		# Vamos adicionar '+ 10' ao Y para que a moeda apareça 10 pixels
		# ABAIXO do centro, mais perto do chão.
		# Ajuste o '10.0' se precisar de mais ou menos altura.
		var offset_x = randf_range(-30, 30)
		coin.global_position = global_position + Vector2(offset_x, 10.0) 
		
		# Adicionar velocidade inicial para fazer os coins espalharem
		var initial_vel = Vector2(randf_range(-100, 100), randf_range(-150, -50))
		
		# Usar call_deferred para garantir que o coin receba a velocidade
		# corretamente no próximo frame de física.
		coin.call_deferred("_apply_initial_velocity", initial_vel)
# --- FIM DO AJUSTE 3 ---


func _on_attack_area_body_entered(body):
	# Esta função pode ser usada para detectar quando o jogador entra na área de ataque
	# Útil para ataques com área específica
	pass

func check_for_player_manually():
	if current_state == State.DEAD:
		return
		
	# Buscar o jogador na cena manualmente
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var distance = position.distance_to(player.position)
		
		# Se o jogador está próximo (raio de 150 pixels)
		if distance < 150:
			print("🔍 DETECÇÃO MANUAL: Jogador encontrado a ", distance, " pixels")
			player_node = player
			current_state = State.CHASE

func _connect_to_player():
	# Buscar o player e conectar ao sinal de saída da tela
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_signal("player_left_screen"):
			if not player.player_left_screen.is_connected(_on_player_left_screen):
				player.player_left_screen.connect(_on_player_left_screen)
	else:
		# Tentar novamente após um pequeno delay
		get_tree().create_timer(0.5).timeout.connect(_connect_to_player)

func _on_player_left_screen():
	# Quando o player sair da tela (cair no limbo), o inimigo apenas volta ao spawn (sem perder vida)
	# IMPORTANTE: Isso só acontece quando o player REALMENTE cai, não quando ele respawna
	if current_state == State.DEAD:
		return
	
	# Verificar se o player realmente caiu (não apenas respawnou)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		
		# Se o player está morto ou caiu para fora, resetar o inimigo
		# Mas verificar se não foi um respawn (posição Y voltou para cima)
		var current_y = player.global_position.y
		
		# Se a posição Y do player voltou para cima (respawnou), não resetar
		if player_last_position_y > 0 and current_y < player_last_position_y - 200:
			# Player respawnou (voltou para cima), não resetar
			player_last_position_y = current_y
			return
		
		# Se o player está muito abaixo (realmente caiu no limbo)
		if current_y > 900:  # Ajuste este valor para o limite de queda do seu jogo
			print("⚠️ Player caiu no limbo! Inimigo voltando ao spawn")
			
			# Voltar para o spawn
			position = start_position
			velocity = Vector2.ZERO
			player_node = null
			current_state = State.PATROL
			is_attacking = false
			
			# Voltar para animação idle/walk
			animated_sprite.play("idle")
		
		# Atualizar última posição conhecida
		player_last_position_y = current_y

extends CharacterBody2D

# Estados do inimigo
enum State { PATROL, CHASE, ATTACK }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $LedgeCheck
@onready var attack_timer = $AttackTimer

# Propriedades do inimigo
const SPEED = 50.0
const ATTACK_RANGE = 40.0
var direction_x = 1 # 1 para a direita, -1 para a esquerda
var player_node = null
var current_state = State.PATROL

# Variável de controle para o ataque
var attack_can_start = true

func _ready():
	# Conecta os sinais das áreas de detecção
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Conecta o sinal do timer para permitir um novo ataque
	attack_timer.timeout.connect(func():
		attack_can_start = true
	)

func _physics_process(delta):
	# Lógica de gravidade
	if not is_on_floor():
		velocity.y += 980 * delta
	
	# Lógica de estados
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.CHASE:
			chase_state(delta)
		State.ATTACK:
			attack_state(delta)
	
	move_and_slide()

# --- Estados do Inimigo ---

func patrol_state(_delta):
	# Virar se estiver perto de cair
	if is_on_floor() and not ledge_check.is_colliding():
		direction_x *= -1
			
	# Animação de caminhada
	animated_sprite.flip_h = direction_x < 0
	animated_sprite.play("walk")
	
	velocity.x = direction_x * SPEED

func chase_state(_delta):
	# Transição para o estado de ataque
	if player_node:
		var distance_to_player = position.distance_to(player_node.position)
		if distance_to_player < ATTACK_RANGE and attack_can_start:
			current_state = State.ATTACK
			attack_can_start = false
			return
		
		# Move em direção ao jogador
		direction_x = sign(player_node.position.x - position.x)
		animated_sprite.flip_h = direction_x < 0
		velocity.x = direction_x * SPEED
		animated_sprite.play("walk")
	else:
		# Volta à patrulha se o jogador não for mais detectado
		current_state = State.PATROL
		animated_sprite.play("idle")

func attack_state(_delta):
	velocity.x = 0
	animated_sprite.play("attack")
	attack_timer.start()
	current_state = State.CHASE

# --- Funções de Detecção ---

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_node = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL

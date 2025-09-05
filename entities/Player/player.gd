extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_timer = $AttackTimer

var is_attacking = false
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

func _ready():
	attack_timer.timeout.connect(func():
		is_attacking = false
	)

func _physics_process(delta):
	# Lógica de Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Lógica de Movimento: Sem travas!
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Lógica de Animação: Prioriza o ataque
	if is_attacking:
		animated_sprite.play("attack")
	elif not is_on_floor():
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

# --- Função de Input para Pulo e Ataque ---
func _unhandled_input(event):
	if event.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		animated_sprite.play("attack")
		attack_timer.start()

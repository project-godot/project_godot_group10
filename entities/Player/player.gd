extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_timer = $AttackTimer

var is_attacking = false
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const JUMP_BUFFER_TIME = 0.1
var jump_buffer_timer = 0.0

func _ready():
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta):
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
	if event.is_action_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		else:
			jump_buffer_timer = JUMP_BUFFER_TIME
	
	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		animated_sprite.play("attack")
		attack_timer.start()
	
	if event.is_action_pressed("ui_cancel"):
		_open_pause_menu()

func _on_attack_timer_timeout():
	is_attacking = false

func _open_pause_menu():
	get_tree().paused = true
	var pause_menu = preload("res://levels/PauseMenu.tscn").instantiate()
	get_tree().current_scene.add_child(pause_menu)

func take_damage(damage: int):
	print("Jogador recebeu ", damage, " de dano!")
	# Aqui você pode implementar seu sistema de vida
	# Por exemplo:
	# health -= damage
	# if health <= 0:
	#     die()

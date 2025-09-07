extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var ledge_check = $LedgeCheck
@onready var attack_timer = $AttackTimer

const SPEED = 50.0
const ATTACK_RANGE = 40.0
const PATROL_DISTANCE = 50.0 
var direction_x = 1 
var player_node = null
var current_state = State.PATROL
var start_position: Vector2 
var left_limit: float  
var right_limit: float  
var attack_can_start = true

func _ready():
	start_position = position
	left_limit = start_position.x - PATROL_DISTANCE
	right_limit = start_position.x + PATROL_DISTANCE
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += 980 * delta
	
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

func chase_state(_delta):
	if player_node:
		var distance_to_player = position.distance_to(player_node.position)
		if distance_to_player < ATTACK_RANGE and attack_can_start:
			current_state = State.ATTACK
			attack_can_start = false
			return
		
		var target_direction = sign(player_node.position.x - position.x)
		
		if player_node.position.x >= left_limit and player_node.position.x <= right_limit:
			direction_x = target_direction
			animated_sprite.flip_h = direction_x < 0
			velocity.x = direction_x * SPEED
			animated_sprite.play("walk")
		else:
			current_state = State.PATROL
			animated_sprite.play("idle")
	else:
		current_state = State.PATROL
		animated_sprite.play("idle")

func attack_state(_delta):
	velocity.x = 0
	animated_sprite.play("attack")
	attack_timer.start()
	current_state = State.CHASE

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_node = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == player_node:
		player_node = null
		current_state = State.PATROL

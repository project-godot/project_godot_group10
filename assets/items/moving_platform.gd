extends Node2D

const  wait_duration := 1.0
#tempo da plataforma parar e voltar
@onready var platform := $platform as AnimatableBody2D
@export var move_speed := 5.0
@export var distance := 160
@export var move_horizontal := true

func _ready() -> void:
	move_platform()

func _physics_process(_delta: float) -> void:
	platform.position = platform.position.lerp(follow, 0.5)


var follow := Vector2.ZERO
var platform_center := 16

func move_platform():
	var move_direction =  Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance
	var duration = move_direction.length() / float(move_speed * platform_center)
	
	var platform_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	platform_tween.tween_property(self, "follow", move_direction, duration)
	platform_tween.tween_property(self, "follow", Vector2.ZERO, duration)

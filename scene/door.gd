extends Node2D

@onready var player = $"../player"
@onready var collision_shape_2d = $StaticBody2D/CollisionShape2D

func _ready():
	pass


func _process(delta):
	if player.is_possessed:
		collision_shape_2d.disabled = true
	else:
		collision_shape_2d.disabled = false

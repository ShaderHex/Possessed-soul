extends Node2D

@onready var player = $"../player"
@onready var collision_shape_2d = $StaticBody2D/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.is_possessed:
		collision_shape_2d.disabled = true
	else:
		collision_shape_2d.disabled = false

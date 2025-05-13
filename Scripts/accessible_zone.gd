extends Area2D

var is_activated = false
@onready var sprite = $Sprite

func _ready():
	var collision = $CollisionShape2D
	collision.shape = RectangleShape2D.new()
	collision.shape.extents = Vector2(16, 16)

func activate():
	is_activated = true
	sprite.frame = 1
	print("Lever activated")

func deactivate():
	is_activated = false
	sprite.frame = 0
	print("Lever deactivated")

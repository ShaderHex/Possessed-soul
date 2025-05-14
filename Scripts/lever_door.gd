extends Node2D

@export var on_texture: Texture2D
@export var off_texture: Texture2D

@onready var sprite = $Sprite2D

var is_open := false

func _ready():
	update_door_visual()

func toggle_door():
	is_open = !is_open
	update_door_visual()
	print("Door toggled:", name, "->", is_open)

func update_door_visual():
	if is_open:
		sprite.texture = on_texture
	elif !is_open:
		sprite.texture = off_texture
		
	
	$StaticBody2D/CollisionShape2D.disabled = is_open  # Disable collision when open

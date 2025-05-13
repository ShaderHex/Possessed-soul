extends Area2D

@export var on_texture: Texture2D
@export var off_texture: Texture2D
@onready var sprite = $Sprite2D
@onready var player = $"../player"

var is_on := false
var is_play_in_range:bool = false

func _ready():
	add_to_group("lever")
	sprite.texture = off_texture
	print("Lever initialized:", name)

func toggle():
	if is_play_in_range:
		is_on = !is_on
		sprite.texture = on_texture if is_on else off_texture
		print("Lever state changed to:", "ON" if is_on else "OFF")

func _on_body_entered(body):
	#TODO: fix the bug where the enemy can't control lever
	if body.is_in_group("enemy"):
		is_play_in_range = true


func _on_body_exited(body):
	is_play_in_range = false

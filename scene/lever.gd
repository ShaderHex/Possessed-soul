extends Area2D

@export var on_texture: Texture2D
@export var off_texture: Texture2D
@onready var sprite = $Sprite2D
@export var connected_doors: Array[NodePath] = []

var is_on := false
var is_play_in_range: bool = false
var interacting_enemy = null

func _ready():
	add_to_group("lever")
	sprite.texture = off_texture
	print("Lever initialized:", name)

func toggle():
	print("Trying to toggle lever")
	print("is_play_in_range:", is_play_in_range)
	print("interacting_enemy:", interacting_enemy)
	if interacting_enemy:
		print("interacting_enemy.is_possessed:", interacting_enemy.is_possessed)

	if is_play_in_range and interacting_enemy and interacting_enemy.is_possessed:
		is_on = !is_on
		sprite.texture = on_texture if is_on else off_texture
		print("Lever state changed to:", "ON" if is_on else "OFF")

		for door_path in connected_doors:
			var door = get_node(door_path)
			if door and door.has_method("toggle_door"):
				door.toggle_door()
	else:
		print("Toggle conditions not met.")
		print(is_play_in_range)
		print(interacting_enemy)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		is_play_in_range = true
		interacting_enemy = body

func _on_body_exited(body):
	if body == interacting_enemy:
		is_play_in_range = false
		interacting_enemy = null

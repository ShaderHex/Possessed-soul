extends CharacterBody2D

var is_possessed = false
var player = null

const SPEED = 200.0
const GRAVITY = 980

@onready var enemy_area = $EnemyArea

func _ready():
	print("Enemy script initialized")

func _physics_process(delta):
	if is_possessed:
		return

	if player != null:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * SPEED
	else:
		velocity.x = 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()
	


func _on_enemy_area_entered(area: Area2D):
	if area.is_in_group("player"):
		player = area.get_parent()
		print("Player entered enemy's area")

func _on_enemy_area_exited(area: Area2D):
	if area.get_parent() == player:
		player = null
		print("Player left enemy's area")

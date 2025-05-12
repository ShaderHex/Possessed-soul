extends CharacterBody2D

var is_possessed = false
var player = null
var original_modulate := Color(1, 1, 1)

@onready var deadzone = $Deadzone
@onready var player_node = $"../player"
@onready var enemy_area = $EnemyArea
@onready var flash_timer = $FlashTimer

const SPEED = 200.0
const GRAVITY = 980

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

func _on_enemy_area_exited(area: Area2D):
	if area.get_parent() == player:
		player = null

func flash_white():
	modulate = Color(1, 1, 1) * 2
	flash_timer.start()

func _on_flash_timer_timeout():
	modulate = original_modulate

func _on_deadzone_body_entered(body):
	if body.name == "player" and not is_possessed:
		player_node.player_health -= 10

func _on_deadzone_body_exited(body):
	if body.name == "player" and not is_possessed:
		deadzone.monitoring = true

func on_possess():
	is_possessed = true
	deadzone.monitoring = false

func on_unpossess():
	is_possessed = false

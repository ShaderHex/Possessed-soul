extends CharacterBody2D

var is_possessed = false
var player = null
var original_modulate := Color(1, 1, 1)

@onready var flash_timer = $FlashTimer
@onready var possessing_sound = $Possessing
@onready var player_node = $"../player"

const SPEED = 80.0
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
	else:
		velocity.y = 0

	move_and_slide()

func _on_ChasePlayer_body_entered(body: Node):
	print("Body entered the enemy: ", body)
	if body.name == "player_area" && !player_node.is_possessed:
		print("Following!")
		player = body

func _on_ChasePlayer_body_exited(body: Node):
	if body == player:
		player = null

func flash_white():
	modulate = Color(1, 1, 1) * 2
	flash_timer.start()

func _on_flash_timer_timeout():
	modulate = original_modulate

func _on_deadzone_body_entered(body):
	print("Deadzone contact with:", body.name)
	if body.is_in_group("player") and not is_possessed:
		if body.has_method("take_damage"):
			body.take_damage(3)
		else:
			push_error("Player has no damage handling!")

func on_possess():
	is_possessed = true
	$Deadzone.set_deferred("monitoring", false)

func on_unpossess():
	is_possessed = false
	move_light_to_player()
	$Deadzone.set_deferred("monitoring", true)

func move_light_to_player():
	var light = $PointLight2D

	if light and player_node:
		light.get_parent().remove_child(light)
		player_node.add_child(light)
		light.global_position = player_node.global_position

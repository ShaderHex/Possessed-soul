extends CharacterBody2D

var is_possessed = false
var player = null
var original_modulate := Color(1, 1, 1)
var is_possessable: bool = false

@onready var sprite_2d = $Sprite2D
@onready var flash_timer = $FlashTimer
@onready var possessing_sound = $Possessing
@onready var player_node = $"../player"

@export var isAttackable = true

const SPEED = 50.0
const GRAVITY = 980

func _physics_process(delta):
	if is_possessed:
		return

	if player != null:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * SPEED

		sprite_2d.flip_h = direction < 0
		sprite_2d.play("chase")
	else:
		velocity.x = 0
		sprite_2d.play("default")

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
	
	move_and_slide()


func _on_ChasePlayer_body_entered(body: Node):
	if isAttackable:
		print("Body entered the enemy: ", body)
		if body.name == "player_area" && !player_node.is_possessed:
			print("Following!")
			player = body

func _on_ChasePlayer_body_exited(body: Node):
	if body == player:
		player = null

func flash_white():
	modulate = Color(1, 1, 1) * 255
	flash_timer.start()

func _on_flash_timer_timeout():
	modulate = original_modulate

func _on_deadzone_body_entered(body):
	print("Deadzone contact with:", body.name)
	if isAttackable:
		if body.is_in_group("player") and not is_possessed:
			if body.has_method("take_damage"):
				body.take_damage(3, true)
			else:
				push_error("Player has no damage handling!")

func on_possess():
	is_possessed = true
	Statistic.possession_count += 1
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


func possessed_move(input_vector: Vector2, delta: float):
	if not is_possessed:
		return
	
	velocity.x = input_vector.x * SPEED
	sprite_2d.flip_h = input_vector.x < 0

	if input_vector.x != 0:
		sprite_2d.play("chase")
	else:
		sprite_2d.play("default")

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	move_and_slide()


func _on_is_possesable_body_entered(body):
	if body.name == "player":
		is_possessable = true


func _on_is_possesable_body_exited(body):
	if body.name == "player":
		is_possessable = false

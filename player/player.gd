# ladies and gentlement, this code is fucked up
# if i ever made this opensource, don't take anything from this instead try to fix it
# this way you'll learn a lot more than trying to make similar system, anyways it works

# also there is a spelling error, which i named shake_strengh instead of shake_strength
# i'm too lazy to change it so yeah whatever it still does work fine

extends CharacterBody2D

@export var randomStrength: float = 5.0
@export var shakeFade: float = 5.0

var player_health := 10
var is_possessed = false
var enemy = null
var in_range_enemies = []
var in_range_levers = []
var current_zoom_level = 1.0
var zoom_rate := 0.1
var shake_intensity = 0.0
var is_zooming_and_shaking = false
var possess_hold_time := 0.0
var possess_threshold := 0.5
var camera_y_offset = -50
var slip_strength := 50
var rng = RandomNumberGenerator.new()
var shake_strengh: float = 0.0
var is_possessing_animation_running = false

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980
const MIN_ZOOM = 0.9

@onready var collision_shape_2d = $CollisionShape2D
@onready var camera_2d = $Camera2D
@onready var health_ui = $"../CanvasLayer/HealthUI"
@onready var player_sprite = $AnimatedSprite2D
@onready var possess_half_time = $PossessHalfTime
@onready var parallax_bg = $"../ParallaxBackground"
@onready var level_1 = $".."

func _ready():
	player_sprite.play("default")
	health_ui.text = str(player_health)
	$player_area.area_entered.connect(_on_player_area_entered)
	$player_area.area_exited.connect(_on_player_area_exited)
	add_to_group("player")

	camera_2d.position_smoothing_enabled = true
	camera_2d.position_smoothing_speed = 5.0

	update_parallax_limits()


func _process(delta):
	health_ui.text = str(player_health)

	var target_position: Vector2
	if is_possessed and enemy:
		target_position = enemy.global_position
	else:
		target_position = global_position

	target_position.y += camera_y_offset

	target_position.y = max(target_position.y, global_position.y)

	camera_2d.global_position = camera_2d.global_position.lerp(target_position, delta * 5)
	
	if is_possessed and enemy:
		$player_area.global_position = enemy.global_position
	else:
		$player_area.global_position = global_position

	if is_zooming_and_shaking:
		current_zoom_level = clamp(current_zoom_level - zoom_rate * delta, MIN_ZOOM, 2.0)
		camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)
		update_parallax_limits()

		shake_intensity = min(shake_intensity + delta * 0.5, 3.0)
		var offset_x = randf_range(-1, 1) * shake_intensity
		var offset_y = randf_range(-1, 1) * shake_intensity
		camera_2d.offset = Vector2(offset_x, offset_y)
	else:
		camera_2d.offset = Vector2.ZERO

	if Input.is_action_pressed("possess") and not is_possessed:
		possess_hold_time += delta
	if possess_hold_time >= possess_threshold and not is_possessed:
		handle_possession_input()
		possess_hold_time = 0.0

	if player_health <= 0:
		print("Player died!")
		is_zooming_and_shaking = false
		shake_intensity = 0.0
		current_zoom_level = 1.0
		camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)
		camera_2d.offset = Vector2.ZERO
		update_parallax_limits()

		level_1.get_tree().paused = true
		await get_tree().create_timer(1.0).timeout

		get_tree().change_scene_to_file("res://scene/death_animation.tscn")
		
	if shake_strengh > 0:
		shake_strengh = lerpf(shake_strengh, 0, shakeFade * delta)
		camera_2d.offset += randomOffset()

func _physics_process(delta):
	if is_possessed and enemy:
		handle_possessed_movement(delta)
	else:
		handle_normal_movement(delta)

func handle_possessed_movement(delta):
	if not enemy:
		return

	if not enemy.is_on_floor():
		enemy.velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and enemy.is_on_floor():
		enemy.velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("left", "right")
	if direction != 0:
		enemy.velocity.x = direction * SPEED
	else:
		enemy.velocity.x = lerp(enemy.velocity.x, 0.0, delta * 10.0)
	enemy.move_and_slide()

	# === ANIMATION LOGIC ===
	var sprite = enemy.get_node("Sprite2D")

	if not enemy.is_on_floor():
		sprite.play("jump")
	elif direction != 0:
		sprite.play("chase")
	else:
		sprite.play("default")

	if direction != 0:
		sprite.flip_h = direction < 0

func handle_normal_movement(delta):
	var direction = 0

	if Input.is_action_pressed("left"):
		direction -= 1
	if Input.is_action_pressed("right"):
		direction += 1

	velocity.x = direction * SPEED

	if direction != 0:
		player_sprite.flip_h = direction > 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if is_possessed:
		enemy.sprite_2d.play("chase")
	
	move_and_slide()

func _input(event):
	if event.is_action_pressed("possess"):
		if is_possessed:
			unpossess_enemy()
		else:
			possess_hold_time = 0.0
	elif event.is_action_released("possess"):
		if not is_possessed and possess_hold_time >= possess_threshold:
			handle_possession_input()
		possess_hold_time = 0.0

	if Input.is_action_just_pressed("interact"):
		print("E pressed - levers in range: ", in_range_levers.size())
		if in_range_levers.size() > 0:
			interact_with_lever()

func _on_player_area_entered(area: Area2D):
	if area.is_in_group("lever"):
		print("LEVER ENTERED!")
		if not in_range_levers.has(area):
			in_range_levers.append(area)
	elif area.get_parent().is_in_group("enemy"):
		print("ENEMY DETECTED!")
		if not in_range_enemies.has(area.get_parent()):
			in_range_enemies.append(area.get_parent())

func _on_player_area_exited(area: Area2D):
	if area.is_in_group("lever"):
		print("LEVER EXITED!")
		if in_range_levers.has(area):
			in_range_levers.erase(area)
	elif area.get_parent().is_in_group("enemy"):
		if in_range_enemies.has(area.get_parent()):
			in_range_enemies.erase(area.get_parent())

func handle_possession_input():
	if not is_possessed and in_range_enemies.size() > 0:
		enemy = get_closest_enemy()
		if enemy:
			possess_enemy()
	elif is_possessed:
		unpossess_enemy()


func get_closest_enemy():
	var closest = null
	var closest_dist = INF
	for e in in_range_enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest = e
			closest_dist = dist
	return closest
func possess_enemy():
	if enemy == null:
		return
	enemy.possessing_sound.play()
	is_possessed = true
	move_light_to_enemy()
	collision_shape_2d.disabled = true
	current_zoom_level += 0.1
	camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)
	update_parallax_limits()
	
	is_possessing_animation_running = true
	player_sprite.play("possessing")
	if enemy != null:
		enemy.on_possess()
		
	await player_sprite.animation_finished

	if not is_possessing_animation_running:
		return
	
	hide()
	$PossessTime.start()
	$PossessHalfTime.start()

func unpossess_enemy():
	is_possessing_animation_running = false
	is_possessed = false
	player_sprite.play("default")
	show()
	collision_shape_2d.disabled = false
	
	if enemy != null:
		global_position = enemy.global_position + Vector2(64, -50)
		enemy.on_unpossess()
		enemy = null

	$PossessTime.stop()
	$PossessHalfTime.stop()
	is_zooming_and_shaking = false
	shake_intensity = 0.0
	current_zoom_level = 1.0
	camera_2d.zoom = Vector2.ONE
	camera_2d.offset = Vector2.ZERO
	update_parallax_limits()


func take_damage(amount: int, isShake: bool):
	if (isShake):
		player_health = max(player_health - amount, 0)
		print("Player took damage! Health: ", player_health)
		apply_shake()
		isShake = false
	else:
		player_health = max(player_health - amount, 0)
		print("Player took damage! Health: ", player_health)
	$PlayerHurt.play()
	
	$AnimatedSprite2D.play("hurt")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("default")

func interact_with_lever():
	var closest_lever = get_closest_lever()
	if closest_lever:
		closest_lever.toggle()

func get_closest_lever():
	var closest = null
	var closest_dist = INF
	for lever in in_range_levers:
		var dist = global_position.distance_to(lever.global_position)
		if dist < closest_dist:
			closest = lever
			closest_dist = dist
	return closest

func _on_possess_time_timeout():
	player_health = 0

func _on_possess_half_time_timeout():
	print("almost")
	is_zooming_and_shaking = true
	take_damage(1, false)

func update_parallax_limits():
	if parallax_bg:
		var view_width = get_viewport_rect().size.x / current_zoom_level
		parallax_bg.limit_left = -view_width * 2
		parallax_bg.limit_right = view_width * 2

func move_light_to_enemy():
	var light = $PointLight2D

	if light and enemy:
		light.get_parent().remove_child(light)
		enemy.add_child(light)
		light.global_position = enemy.global_position

func apply_fan_effect():
	var camera = $Camera2D
	if camera:
		camera.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		await get_tree().create_timer(0.05).timeout
		camera.offset = Vector2.ZERO

	if global_position.x < $"../Vent".global_position.x:
		velocity.x -= slip_strength
	else:
		velocity.x += slip_strength

func apply_shake():
	print("Applying shake")
	print("Shake Strength: ", shake_strengh)
	shake_strengh = randomStrength

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strengh, shake_strengh), rng.randf_range(-shake_strengh, shake_strengh))

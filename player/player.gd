extends CharacterBody2D

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
var possess_threshold := 1.0
var camera_y_offset = -50

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980
const MIN_ZOOM = 0.9

@onready var collision_shape_2d = $CollisionShape2D
@onready var camera_2d = $Camera2D
@onready var health_ui = $"../CanvasLayer/HealthUI"
@onready var player_sprite = $AnimatedSprite2D
@onready var possess_half_time = $PossessHalfTime
@onready var parallax_bg = $"../ParallaxBackground"  # Adjust path as needed

func _ready():
	player_sprite.play("default")
	health_ui.text = str(player_health)
	$player_area.area_entered.connect(_on_player_area_entered)
	$player_area.area_exited.connect(_on_player_area_exited)
	add_to_group("player")

	# Godot 4 camera smoothing
	camera_2d.position_smoothing_enabled = true
	camera_2d.position_smoothing_speed = 5.0

	update_parallax_limits()


func _process(delta):
	health_ui.text = str(player_health)

	# Camera positioning with Y offset
	var target_position: Vector2
	if is_possessed and enemy:
		target_position = enemy.global_position
	else:
		target_position = global_position

	target_position.y += camera_y_offset
	camera_2d.global_position = camera_2d.global_position.lerp(target_position, delta * 5)
	
	# Player area positioning (without offset)
	if is_possessed and enemy:
		$player_area.global_position = enemy.global_position
	else:
		$player_area.global_position = global_position

	# Zoom + Shake logic
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

	# Possession hold logic
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

func _physics_process(delta):
	if is_possessed and enemy:
		handle_possessed_movement(delta)
	else:
		handle_normal_movement(delta)

func handle_possessed_movement(delta):
	if not enemy.is_on_floor():
		enemy.velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and enemy.is_on_floor():
		enemy.velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("ui_left", "ui_right")
	enemy.velocity.x = direction * SPEED if direction else move_toward(enemy.velocity.x, 0, SPEED)
	enemy.move_and_slide()

func handle_normal_movement(delta):
	var direction = 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	velocity.x = direction * SPEED

	if direction != 0:
		player_sprite.flip_h = direction > 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()

func _input(event):
	if event.is_action_pressed("possess"):
		if is_possessed:
			unpossess_enemy()
		else:
			# Start tracking hold time for possession
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
	enemy.possessing_sound.play()
	is_possessed = true
	collision_shape_2d.disabled = true
	current_zoom_level += 0.1
	camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)
	update_parallax_limits()
	player_sprite.play("possessing")
	await player_sprite.animation_finished
	hide()
	enemy.on_possess()
	$PossessTime.start()
	$PossessHalfTime.start()

func unpossess_enemy():
	is_possessed = false
	player_sprite.play("default")
	show()
	collision_shape_2d.disabled = false
	global_position = enemy.global_position + Vector2(64, -50)
	enemy.on_unpossess()
	enemy = null
	$PossessTime.stop()
	$PossessHalfTime.stop()
	is_zooming_and_shaking = false
	shake_intensity = 0.0
	current_zoom_level = clamp(current_zoom_level + 0.1, MIN_ZOOM, 2.0)
	camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)
	camera_2d.offset = Vector2.ZERO
	update_parallax_limits()

func take_damage(amount: int):
	player_health = max(player_health - amount, 0)
	print("Player took damage! Health: ", player_health)

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
	take_damage(1)

func update_parallax_limits():
	if parallax_bg:
		var view_width = get_viewport_rect().size.x / current_zoom_level
		parallax_bg.limit_left = -view_width * 2
		parallax_bg.limit_right = view_width * 2

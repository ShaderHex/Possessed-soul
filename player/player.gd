# ladies and gentlement, this code is fucked up
# if i ever made this opensource, don't take anything from this instead try to fix it
# this way you'll learn a lot more than trying to make similar system, anyways it works

# also there is a spelling error, which i named shake_strengh instead of shake_strength
# i'm too lazy to change it so yeah whatever it still does work fine

extends CharacterBody2D

@export var randomStrength: float = 5.0
@export var shakeFade: float = 5.0

var player_health := 9
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
var unpossess_x: int = 64
var unpossess_y: int = -50
var isStuck: bool = false
var body_name: String
var possessable_enemies = []
var coyote_time := 0.2
var coyote_timer := 0.0
var jump_buffer_time := 0.15
var jump_buffer_timer := 0.0

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980
const MIN_ZOOM = 0.9

@onready var collision_shape_2d = $CollisionShape2D
@onready var camera_2d = $Camera2D
@onready var player_sprite = $AnimatedSprite2D
@onready var possess_half_time = $PossessHalfTime
@onready var parallax_bg = $"../ParallaxBackground"
@onready var level_1 = $".."

func _ready():
	player_sprite.play("default")
	$player_area.area_entered.connect(_on_player_area_entered)
	$player_area.area_exited.connect(_on_player_area_exited)
	add_to_group("player")

	camera_2d.position_smoothing_enabled = true
	camera_2d.position_smoothing_speed = 5.0

	update_parallax_limits()


func _process(delta):
	var target_position: Vector2
	
	if isStuck:
		print("Player might be stuck with ", body_name)
	
	if is_possessed and enemy != null:
		target_position = enemy.global_position
	else:
		target_position = global_position


	target_position.y += camera_y_offset

	target_position.y = max(target_position.y, global_position.y)

	camera_2d.global_position = camera_2d.global_position.lerp(target_position, delta * 5)
	
	if is_possessed and enemy != null:
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

	var direction = Input.get_axis("left", "right")

	if direction != 0:
		enemy.velocity.x = direction * 100
	else:
		enemy.velocity.x = lerp(enemy.velocity.x, 0.0, delta * 10.0)
	enemy.move_and_slide()

	var sprite = enemy.get_node("Sprite2D")

	if not enemy.is_on_floor():
		sprite.play("jump")
		$footstep.stop()
	elif direction != 0:
		sprite.play("chase")
		if not $footstep.playing:
			$footstep.play()
	else:
		sprite.play("default")
		$footstep.stop()

	if direction != 0:
		sprite.flip_h = direction < 0

func handle_normal_movement(delta):
	var velocity = self.velocity
	var direction = 0

	if Input.is_action_pressed("left"):
		direction -= 1
	if Input.is_action_pressed("right"):
		direction += 1

	var target_speed = direction * SPEED
	var accel = 10.0 if is_on_floor() else 4.0
	velocity.x = lerp(velocity.x, target_speed, delta * accel)

	if direction != 0:
		player_sprite.flip_h = direction > 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		coyote_timer = coyote_time

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	coyote_timer -= delta
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	if not is_on_floor():
		player_sprite.play("jump")
	elif direction != 0:
		player_sprite.play("chase")
	else:
		player_sprite.play("default")

	self.velocity = velocity
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
	if not is_possessed:
		var valid = in_range_enemies.filter(func(e):
			return e.is_possessable
		)
		if valid.size() > 0:
			enemy = get_closest_enemy_from_list(valid)
			if enemy:
				possess_enemy()
	else:
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

	if enemy != null:
		var enemy_sprite = enemy.get_node("Sprite2D")
		var direction = -1 if enemy_sprite.flip_h else 1
		var target_position = enemy.global_position + Vector2(unpossess_x * direction, unpossess_y)

		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			enemy.global_position,
			target_position,
			1 << 0,
			[self, enemy]
		)
		var ray_result = space_state.intersect_ray(query)
		if ray_result:
			target_position = ray_result.position - Vector2(direction * 2, 0)

		collision_shape_2d.disabled = true
		global_position = target_position
		await get_tree().process_frame
		collision_shape_2d.disabled = false

		var max_attempts = 3
		for i in range(max_attempts):
			var collision = move_and_collide(Vector2.ZERO, true, 0.001)
			if collision:
				var push_vector = collision.get_normal() * 16
				global_position += push_vector
				modulate = Color.RED
				await get_tree().create_timer(0.1).timeout
				modulate = Color.WHITE
			else:
				break

		if move_and_collide(Vector2.ZERO, true, 0.001):
			global_position.y -= 32
			modulate = Color.BLUE
			await get_tree().create_timer(0.1).timeout
			modulate = Color.WHITE

		camera_2d.position_smoothing_enabled = false
		camera_2d.global_position = global_position + Vector2(0, camera_y_offset)
		await get_tree().process_frame
		await get_tree().process_frame
		camera_2d.position_smoothing_enabled = true

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
	var vents = get_tree().get_nodes_in_group("vents")
	
	var closest_vent : Node2D = null
	var closest_distance = INF
	
	for vent in vents:
		if is_instance_valid(vent) && vent.has_method("global_position"):
			var distance = global_position.distance_to(vent.global_position)
			if distance < closest_distance:
				closest_vent = vent
				closest_distance = distance
	
	if closest_vent:
		if global_position.x < closest_vent.global_position.x:
			velocity.x -= slip_strength
		else:
			velocity.x += slip_strength
	else:
		printerr("No valid vents found in group!")

func apply_shake():
	print("Applying shake")
	print("Shake Strength: ", shake_strengh)
	shake_strengh = randomStrength

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strengh, shake_strengh), rng.randf_range(-shake_strengh, shake_strengh))


func _on_is_stuck_body_entered(body):
	pass

func get_closest_enemy_from_list(list_of_enemies: Array) -> CharacterBody2D:
	var closest : CharacterBody2D = null
	var closest_dist = INF
	for e in list_of_enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest = e
			closest_dist = dist
	return closest

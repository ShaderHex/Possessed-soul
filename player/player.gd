#TODO: fix the bug where the enemy can't control lever
extends CharacterBody2D

var player_health := 10
var is_possessed = false
var enemy = null
var in_range_enemies = []
var in_range_levers = []
var current_zoom_level = 1.0

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980

@onready var collision_shape_2d = $CollisionShape2D
@onready var camera_2d = $Camera2D
@onready var health_ui = $"../CanvasLayer/HealthUI"

func _ready():
	health_ui.text = str(player_health)
	$player_area.area_entered.connect(_on_player_area_entered)
	$player_area.area_exited.connect(_on_player_area_exited)
	add_to_group("player")

func _process(delta):
	health_ui.text = str(player_health)
	camera_2d.global_position = enemy.global_position if is_possessed else global_position
	
	if player_health <= 0:
		print("Player died!")

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
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED if direction else move_toward(velocity.x, 0, SPEED)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()

func _on_player_area_entered(area: Area2D):
	# Lever detection fix
	if area.is_in_group("lever"):
		print("LEVER ENTERED!")
		if not in_range_levers.has(area):
			in_range_levers.append(area)
	elif area.get_parent().is_in_group("enemy"):
		print("ENEMY DETECTED!")
		if not in_range_enemies.has(area.get_parent()):
			in_range_enemies.append(area.get_parent())

func _on_player_area_exited(area: Area2D):
	# Lever exit fix
	if area.is_in_group("lever"):
		print("LEVER EXITED!")
		if in_range_levers.has(area):
			in_range_levers.erase(area)
	elif area.get_parent().is_in_group("enemy"):
		if in_range_enemies.has(area.get_parent()):
			in_range_enemies.erase(area.get_parent())

func _input(event):
	if Input.is_action_just_pressed("possess"):
		handle_possession_input()
	if Input.is_action_just_pressed("interact"):
		print("E pressed - levers in range: ", in_range_levers.size())
		if in_range_levers.size() > 0:
			interact_with_lever()

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
	is_possessed = true
	hide()
	collision_shape_2d.disabled = true
	enemy.on_possess()
	current_zoom_level += 0.1
	camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)

func unpossess_enemy():
	is_possessed = false
	show()
	collision_shape_2d.disabled = false
	global_position = enemy.global_position + Vector2(64, -50)
	enemy.on_unpossess()
	enemy = null
	current_zoom_level -= 0.1
	camera_2d.zoom = Vector2(current_zoom_level, current_zoom_level)

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

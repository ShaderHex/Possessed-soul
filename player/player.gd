extends CharacterBody2D

@onready var player_health = 10

var is_possessed = false
var enemy = null
var in_range_enemies = []
var current_zoom_level = 1.0
var zoom_factor = 1.1

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980

@onready var player_area = $player_area
@onready var collision_shape_2d = $CollisionShape2D
@onready var camera_2d = $Camera2D
@onready var enemy_node = $"../Enemy"

func _ready():
	if player_area:
		player_area.connect("area_entered", _on_player_area_entered)
		player_area.connect("area_exited", _on_player_area_exited)
	print("Ready: Player initialized.")

func _process(delta):
	if is_possessed and enemy:
		camera_2d.global_position = enemy.global_position
	else:
		camera_2d.global_position = self.global_position
		
	if player_health <= 0:
		print("Dead!")

func _physics_process(delta):
	if is_possessed and enemy:
		if not enemy.is_on_floor():
			enemy.velocity.y += GRAVITY * delta
		if Input.is_action_just_pressed("ui_accept") and enemy.is_on_floor():
			enemy.velocity.y = JUMP_VELOCITY
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			enemy.velocity.x = direction * SPEED
		else:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0, SPEED)
		enemy.move_and_slide()
	else:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		move_and_slide()

func _on_player_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent.is_in_group("enemy") and not in_range_enemies.has(parent):
		in_range_enemies.append(parent)
		print("Entered range of enemy: ", parent.name)

func _on_player_area_exited(area: Area2D):
	var parent = area.get_parent()
	if parent in in_range_enemies:
		in_range_enemies.erase(parent)
		print("Exited range of enemy: ", parent.name)

func _input(event):
	if Input.is_action_just_pressed("possess"):
		print("Possess key pressed")
		if not is_possessed and in_range_enemies.size() > 0:
			enemy = get_closest_enemy()
			print("Attempting to possess closest enemy: ", enemy)
			if enemy:
				possess_enemy()
		elif is_possessed:
			print("Unpossessing enemy.")
			unpossess_enemy()
		else:
			print("No enemies in range to possess.")

func get_closest_enemy():
	var closest = null
	var closest_dist = INF
	for e in in_range_enemies:
		var dist = global_position.distance_to(e.global_position)
		print("Checking enemy: ", e.name, " Distance: ", dist)
		if dist < closest_dist:
			closest = e
			closest_dist = dist
	return closest

func possess_enemy():
	if enemy:
		print("Possessing enemy: ", enemy.name)
		is_possessed = true
		hide()
		collision_shape_2d.disabled = true
		enemy.is_possessed = true
		current_zoom_level += 0.1
		camera_2d.zoom.x = current_zoom_level
		camera_2d.zoom.y = current_zoom_level
		enemy_node.get_node("Deadzone").monitoring = false
		if enemy.has_method("flash_white"):
			enemy.flash_white()
		else:
			print("Warning: Enemy has no flash_white method!")

func unpossess_enemy():
	if enemy:
		print("Unpossessing enemy: ", enemy.name)
		is_possessed = false
		show()
		collision_shape_2d.disabled = false
		self.global_position = enemy.global_position + Vector2(32, 0)
		enemy.on_unpossess()
		enemy = null
		current_zoom_level -= 0.1
		camera_2d.zoom.x = current_zoom_level
		camera_2d.zoom.y = current_zoom_level

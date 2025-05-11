extends CharacterBody2D

var is_possessed = false
var enemy = null
var original_script = null

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980

@onready var player_area = $player_area

func _ready():
	original_script = self.get_script()
	
	if player_area:
		player_area.connect("area_entered", _on_player_area_entered)
		player_area.connect("area_exited", _on_player_area_exited)
		print("Player script initialized")
	else:
		printerr("PlayerArea node is missing!")


func _physics_process(delta):
	if is_possessed:
		if enemy == null:
			return

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
	print("Area entered:", area.name)
	if area.is_in_group("enemy"):
		enemy = area.get_parent()
		print("Enemy detected:", enemy.name)


func _on_player_area_exited(area: Area2D):
	if area.is_in_group("enemy") and area.get_parent() == enemy:
		enemy = null
		print("Enemy left player's area")

func _input(event):
	if Input.is_action_just_pressed("possess"):
		print("P pressed! Enemy is null:", enemy == null) 
		if enemy != null:
			print("Attempting possession...")
			possess_enemy()


func possess_enemy():
	if enemy:
		print("Possessing enemy:", enemy.name)
		is_possessed = true
		hide() 
		enemy.is_possessed = true 

func unpossess_enemy():
	if enemy:
		is_possessed = false
		show()
		enemy.is_possessed = false 
		enemy = null

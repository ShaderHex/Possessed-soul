extends AnimatedSprite2D

@onready var player = $"../player"
@onready var damage_timer = $DamageTimer
@export var hasPhysics: bool = false
@onready var airflow: AnimatedSprite2D = $airflow

var damage = 1
var player_in_area = false
var enemies_in_area = []
var isOn: bool = true

func _ready():
	self.play("default")
	airflow.play("default")
	damage_timer.wait_time = 1.0
	_update_state()

func _process(delta: float) -> void:
	if isOn and hasPhysics:
		for enemy in enemies_in_area:
			if is_instance_valid(enemy):
				print("Before push, enemy velocity:", enemy.velocity)
				enemy.velocity.y = -200
				print("After push, enemy velocity:", enemy.velocity)


func _on_area_2d_body_entered(body):
	print("Body entered to fan: ", body)
	
	if isOn:
		if body.name == "player" and not player.is_possessed:
			print("Fan close code executed")
			print("Current player health from fan system: ", player.player_health)
			player_in_area = true
			damage = 1
			damage_timer.start()

		if body.is_in_group("enemy"):
			print("enemy entered")
			if not enemies_in_area.has(body):
				enemies_in_area.append(body)

func _on_area_2d_body_exited(body):
	if body.name == "player":
		player_in_area = false
		damage_timer.stop()

	if body.is_in_group("enemy"):
		if enemies_in_area.has(body):
			enemies_in_area.erase(body)

func _on_DamageTimer_timeout():
	if isOn and player_in_area and not player.is_possessed:
		print("Fan damage: ", damage)
		player.take_damage(damage, true)
		damage = min(damage * 2, 10)
		player.apply_fan_effect()

func toggle_door():
	isOn = !isOn
	_update_state()

func _update_state():
	if isOn:
		airflow.show()
		if player_in_area and not player.is_possessed:
			damage_timer.start()
		else:
			damage_timer.stop()
	else:
		airflow.hide()
		damage_timer.stop()

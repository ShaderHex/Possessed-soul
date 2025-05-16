extends AnimatedSprite2D

@onready var player = $"../player"
@onready var damage_timer = $DamageTimer

var damage = 1
var player_in_area = false

func _ready():
	self.play("default")
	$airflow.play("default")
	damage_timer.wait_time = 1.0

func _on_area_2d_body_entered(body):
	print("Body entered to fan: ", body)
	if body.name == "player" and not player.is_possessed:
		print("Fan close code excuted")
		print("Current player health from fam system: ", player.player_health)
		player_in_area = true
		damage = 1
		damage_timer.start()

func _on_area_2d_body_exited(body):
	if body.name == "player":
		player_in_area = false
		damage_timer.stop()

func _on_DamageTimer_timeout():
	if player_in_area and not player.is_possessed:
		print("Fan damage: ", damage)
		player.take_damage(damage)
		damage = min(damage * 2, 10)
		player.apply_fan_effect()

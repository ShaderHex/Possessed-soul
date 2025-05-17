extends RigidBody2D

var speed = 350
var damage = 1

func _ready():
	$LifetimeTimer.start(2)

func launch(direction: Vector2):
	linear_velocity = direction * speed

func _on_LifetimeTimer_timeout():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, true)
	queue_free() # Delete on hit

extends Node2D

@onready var sprite = $Sprite2D
@onready var level_1 = $"."

func _ready():
	$".".get_tree().paused = false
	var tween = create_tween()

	tween.tween_property(sprite, "position:y", sprite.position.y + 200, 1.0)

	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)

	tween.tween_callback(Callable(self, "_on_fall_done"))
	$Gameover.play()

func _on_fall_done():
	sprite.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scene/death_screen.tscn")

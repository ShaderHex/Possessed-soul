extends Node2D

var time := 0.0
var amplitude := 50.0
var frequency := 1.0
var velocity := Vector2.ZERO
var enemies = []

@export var fade_rect: ColorRect
@onready var sprite_2d = $Sprite2D
@export var scene_path: String

func _ready():
	enemies = get_tree().get_nodes_in_group("enemies")

func _process(delta):
	time += delta
	velocity.y = sin(time * frequency * TAU) * amplitude
	sprite_2d.position.y += velocity.y * delta

func _on_area_2d_body_entered(body):
	if body.name == "player":
		for enemy in enemies:
			if enemy.has_variable("isAttackable"):
				enemy.isAttackable = false
		await fade_in()
		self.queue_free()
		print("player entered, crystal removed")
		get_tree().change_scene_to_file(scene_path)

func fade_in(duration := 1.0):
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

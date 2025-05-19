extends Node2D

@onready var background_sound = $BackgroundSound
@onready var water_dripping = $WaterDripping
@onready var player = $player
@onready var fade_rect = $CanvasLayer/FadeRect
@export var scene_path: String


func _ready():
	fade_out()
	background_sound.play()
	water_dripping.play()

func _process(delta):
	if player.player_health < 9:
		$CanvasLayer/HBoxContainer/TextureRect3.hide()
	if player.player_health < 6:
		$CanvasLayer/HBoxContainer/TextureRect2.hide()
	if player.player_health < 3:
		$CanvasLayer/HBoxContainer/TextureRect.hide()

func _on_audio_stream_player_2d_finished():
	background_sound.play()
	print("Finished restarting...")


func _on_water_dripping_finished():
	water_dripping.play()
	print("Finished restarting...")


func fade_in(duration := 1.0):
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_out(duration := 1.0):
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	fade_rect.visible = false


func _on_restart_pressed():
	get_tree().change_scene_to_file(scene_path)

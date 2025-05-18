extends Node2D

@onready var background_sound = $BackgroundSound
@onready var water_dripping = $WaterDripping
@onready var player = $player


func _ready():
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

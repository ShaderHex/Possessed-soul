extends Node2D

@onready var background_sound = $BackgroundSound
@onready var water_dripping = $WaterDripping


# Called when the node enters the scene tree for the first time.
func _ready():
	background_sound.play()
	water_dripping.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_audio_stream_player_2d_finished():
	background_sound.play()
	print("Finished restarting...")


func _on_water_dripping_finished():
	water_dripping.play()
	print("Finished restarting...")

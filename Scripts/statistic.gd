extends Node

var play_time := 0.0
var possession_count := 0
var damage_taken := 0

func _process(delta):
	if not get_tree().paused:
		play_time += delta

func reset():
	play_time = 0.0
	possession_count = 0
	damage_taken = 0

func get_formatted_play_time() -> String:
	var total_seconds := int(play_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

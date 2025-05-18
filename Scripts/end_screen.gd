extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var formatted_time = Statistic.get_formatted_play_time()
	$CanvasLayer/TotalTimeNum.text = str(formatted_time)
	$CanvasLayer/PossessionUsedNum.text = str(Statistic.possession_count)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Node2D

@onready var player = $"../player"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_dead_zone_body_entered(body):
	if body.name == "player" || body.is_in_group("enemy"):
		player.player_health = 0
		print("Player died")

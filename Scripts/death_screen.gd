extends CanvasLayer

@onready var overlay = $BlackOverlay
@onready var retry_button = $RetryButton
@onready var menu_button = $MenuButton
@onready var death_label = $DeathLabel
@onready var death_sound = $DeathSound

var is_active = false

func _ready():
	retry_button.visible = false
	menu_button.visible = false
	death_label.visible = false
	overlay.color.a = 0.0
	add_to_group("DeathScreen")

func show_death_screen():
	if is_active:
		return
	is_active = true

	get_tree().paused = true
	overlay.show()

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 1.0) # Fade in overlay

	await get_tree().create_timer(1.0).timeout

	var player = get_parent().get_node("player")
	player.fall_on_death()

	#death_sound.play()

	await get_tree().create_timer(1.0).timeout

	retry_button.visible = true
	menu_button.visible = true
	death_label.visible = true

func _on_retry_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")

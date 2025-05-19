extends Control

@export var menu: NinePatchRect
@export var credit: NinePatchRect
@export var animation_player: AnimationPlayer
@onready var title = $Title
@onready var main_menu = $MainMenu

enum STATE { MENU, CREDIT }
var ui_state = STATE.MENU
var isTitleVisible: bool = true

func _input(event):
	if event.is_action_pressed("ui_cancel") and not animation_player.is_playing():
		if isTitleVisible == false:
			print("Title were invisible, making it visible")
			isTitleVisible = true
			print("Title", isTitleVisible)
		match ui_state:
			STATE.MENU:
				animation_player.play("hide_menu")
			STATE.CREDIT:
				hide_and_show("credit", "menu", STATE.MENU)
				

func _ready():
	$MainMenu.play()

func _process(delta):
	if isTitleVisible:
		title.show()
	else:
		title.hide()

func hide_and_show(first: String, second: String, new_state: int):
	animation_player.play("hide_" + first)
	await animation_player.animation_finished
	animation_player.play("show_" + second)
	ui_state = new_state

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scene/tutorial_level.tscn")

func _on_credit_pressed():
	if isTitleVisible:
		isTitleVisible = false
		
	hide_and_show("menu", "credit", STATE.CREDIT)

func _on_exit_pressed():
	get_tree().quit()


func _on_main_menu_finished():
	$MainMenu.play()

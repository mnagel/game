extends Control

var player # the backing player

onready var sfx = $sfx

func update():
	$player_name.text = player.display_name
	$bot.pressed = player.bot
	
	if player.bot:
		$avatar.texture = load("res://assets/avatars/bot.png")
	else:
		$avatar.texture = load("res://assets/avatars/human.png")
	$avatar.modulate = player.color

func _ready():
	update()


func _on_bot_toggled(button_pressed):
	if global.sound: sfx.play()
	player.bot = button_pressed
	update()


func _on_player_name_text_changed(new_text):
	player.name = new_text
	update()


func _on_remove_pressed():
	if global.sound: sfx.play()
	GameState.delPlayer(player)
	get_parent().remove_child(self)

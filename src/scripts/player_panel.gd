extends Control

var player # the backing player

func update():
	$player_name.text = player.name
	$bot.pressed = player.bot
	
	if player.bot:
		$avatar.texture = load("res://assets/avatars/bot.png")
	else:
		$avatar.texture = load("res://assets/avatars/human.png")
	$avatar.modulate = player.color

func _ready():
	update()


func _on_bot_toggled(button_pressed):
	player.bot = button_pressed
	update()


func _on_player_name_text_changed(new_text):
	player.name = new_text
	update()


func _on_remove_pressed():
	GameState.players.erase(player)
	
	# Remove self
	get_parent().remove_child(self)

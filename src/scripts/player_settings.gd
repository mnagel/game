extends Control


func getRandName():
	var names = [
		"Data",
		"Plex",
		"Opak", 
		"Fiber",
		"H3X", 
		"BU4", 
		"N34", 
		"Beta", 
		"Alpha",
		"CC20",
		"Otis",
		"Tink",
		"Otk", 
		"Cori",
		"Agxt", 
		"Screw", 
		"Cybel", 
		"Spark", 
		"Plier", 
		"Oyz"
	]
	return names[randi() % names.size()]

var player_name = getRandName()
var color = "none"
var bot = false


func _ready():
	if global.colors.size() and color == "none":
		color = global.colors[rand_range(0, global.colors.size() - 1)]
	elif color == "none":
		return
	global.colors.erase(color)
	$bot.pressed = bot
	if bot:
		$avatar.texture = load("res://assets/avatars/bot-" + color + ".png")
	else:
		$avatar.texture = load("res://assets/avatars/human-" + color + ".png")
	$player_name.text = player_name


func generateDict():
	var dict = {color: {"name": player_name, "score": 0, "total_score": 0, "bot": bot}}
	return dict


func _on_bot_toggled(button_pressed):
	bot = button_pressed
	if bot:
		$avatar.texture = load("res://assets/avatars/bot-" + color + ".png")
	else:
		$avatar.texture = load("res://assets/avatars/human-" + color + ".png")


func _on_player_name_text_changed(new_text):
	player_name = new_text


func _on_remove_pressed():
	global.players.erase(color)
	global.num_players -= 1
	if color in global.colors:
		pass
	else:
		global.colors.append(color)
	get_parent().remove_child(self)

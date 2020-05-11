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
		"Oyz",
		"Fooba"
	]
	return names[randi() % names.size()]

var player_identifier = ""
var player_name = getRandName() # FIXME broken for initial two players
var color = ""
var bot = false

func _ready():
	if color == "":
		if len(global.available_colors):
			color = global.available_colors[rand_range(0, global.available_colors.size() - 1)]
		else:
			# Should not happen
			return
	
	player_identifier = color
	
	global.available_colors.erase(color)
	$bot.pressed = bot
	set_avatar()
	$player_name.text = player_name


func set_avatar():
	if bot:
		$avatar.texture = load("res://assets/avatars/bot.png")
	else:
		$avatar.texture = load("res://assets/avatars/human.png")
	$avatar.modulate = ColorN(color)


func generateDict():
	return {
		"identifier": player_identifier,
		"name": player_name,
		"color": color,
		"bot": bot,
		"score": 0,
		"total_score": 0
	}


func _on_bot_toggled(button_pressed):
	bot = button_pressed
	set_avatar()


func _on_player_name_text_changed(new_text):
	player_name = new_text


func _on_remove_pressed():
	# Erase player
	global.players.erase(color)
	
	# Return color to global available colors
	if color in global.available_colors:
		pass
	else:
		global.available_colors.append(color)
	
	# Remove self
	get_parent().remove_child(self)

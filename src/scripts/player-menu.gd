extends Control


# Player node
var player_settings = preload("res://scenes/player_settings.tscn")

# Nodes
onready var players_container = $scroll/container
onready var lp_msg = $messages # when players are less than 2

onready var sfx = $sfx

# Builtin
func _ready():
	global.num_players = len(global.players.keys())
	for key in global.players.keys(): # get the available players
		var instancedPlayerSettings = player_settings.instance()
		instancedPlayerSettings.color = key
		instancedPlayerSettings.player_name = global.players[key]["name"]
		instancedPlayerSettings.bot = global.players[key]["bot"]
		players_container.add_child(instancedPlayerSettings)

func _process(_delta):
	var _players = players_container.get_children()
	if len(_players) < 2: # minimum number of players
		lp_msg.visible = true
	else:
		lp_msg.visible = false

# Signals
func _on_play_pressed():
	if global.sound: sfx.play()
	var _players = $scroll/container.get_children()
	if len(_players) < 2: # minimum number of players
		pass
	else:
		for ps in _players:
			var dict = ps.generateDict()
			global.players[dict.keys()[0]] = dict[dict.keys()[0]]
		get_tree().change_scene("res://scenes/main.tscn")
	

func on_bot_toggled(button_pressed, extra_arg_0):
	global.players[global.players.keys()[extra_arg_0-1]]["bot"] = button_pressed
	if global.sound: sfx.play()

func _on_player_name_text_entered(new_text, extra_arg_0):
	global.players[global.players.keys()[extra_arg_0-1]]["name"] = new_text

func _on_add_pressed():
	if len(global.colors):
		var instancedPlayerSettings = player_settings.instance()
		global.num_players += 1
		players_container.add_child(instancedPlayerSettings)
		if global.sound: sfx.play()

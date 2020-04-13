extends Control


# Player node
var player_settings = preload("res://scenes/player_settings.tscn")

# Nodes
onready var players_container = $scroll/container
onready var lp_msg = $messages # when players are less than 2
onready var anticheat_cbox = $vbox/anticheat # checkbox
onready var anticheat = $anticheat


onready var sfx = $sfx

# Builtin
func _ready():
	global.num_players = len(global.players.keys())
	anticheat_cbox.pressed = global.anticheat
	for key in global.players.keys(): # get the available players
		var instancedPlayerSettings = player_settings.instance()
		instancedPlayerSettings.color = key
		instancedPlayerSettings.player_name = global.players[key]["name"]
		instancedPlayerSettings.bot = global.players[key]["bot"]
		players_container.add_child(instancedPlayerSettings)

func _process(delta):
	var _players = players_container.get_children()
	if len(_players) < 2: # minimum number of players
		lp_msg.visible = true
	else:
		lp_msg.visible = false
	anticheat.visible = global.anticheat

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

func _on_anticheat_toggled(btn):
	global.anticheat = btn

extends Control


# Player node
var Player = preload("res://scenes/player.tscn")

# Nodes
onready var players_container = $scroll/container
onready var lp_msg = $messages # when players are less than 2
onready var tutorial_popup = $tutorial

onready var sfx = $sfx

# Builtin
func _ready():
	if global.players.size() == 0:
		_on_add_pressed()
		_on_add_pressed()
	
	for player in global.players.values(): # get the available players
		var instancedPlayerSettings = Player.instance()
		instancedPlayerSettings.player_identifier = player["identifier"]
		instancedPlayerSettings.player_name = player["name"]
		instancedPlayerSettings.color = player["color"]
		instancedPlayerSettings.bot = player["bot"]
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
			global.setPlayer(dict)
		get_tree().change_scene("res://scenes/main.tscn")

func on_bot_toggled(button_pressed, extra_arg_0):
	global.getPlayerByIdentifier(extra_arg_0)["bot"] = button_pressed
	if global.sound: sfx.play()

func _on_player_name_text_entered(new_text, extra_arg_0):
	global.getPlayerByIdentifier(extra_arg_0)["name"] = new_text

func _on_add_pressed():
	if len(global.available_colors):
		var instancedPlayerSettings = Player.instance()
		players_container.add_child(instancedPlayerSettings)
		if global.sound: sfx.play()
		
func _on_tutorial_pressed():
	tutorial_popup.popup()


func _on_close_pressed():
	tutorial_popup.visible = false

extends Control

# Player node
var PlayerPanel = preload("res://scenes/player_panel.tscn")

# Nodes
onready var players_container = $scroll/container
onready var lp_msg = $messages # when players are less than 2
onready var tutorial_popup = $tutorial

onready var sfx = $sfx

# Builtin
func _ready():
	# re-add previous players
	for player in GameState.getAllPlayers(): # get the available players
		var myPlayerPanel = PlayerPanel.instance()
		myPlayerPanel.player = player
		myPlayerPanel.update()
		players_container.add_child(myPlayerPanel)
		
	if GameState.getPlayerCount() == 0:
		_on_add_pressed()
		_on_add_pressed()

func _process(_delta):
	var players = players_container.get_children()
	if len(players) < 2: # minimum number of players
		lp_msg.visible = true
	else:
		lp_msg.visible = false

var Main = preload("res://scenes/main.tscn")

# Signals
func _on_play_pressed():
	if global.sound: sfx.play()
	var players = $scroll/container.get_children()
	if len(players) < 2: # minimum number of players
		pass
	else:
		get_tree().change_scene("res://scenes/main.tscn")

func on_bot_toggled(button_pressed, extra_arg_0):
	GameState.getPlayerByIdentifier(extra_arg_0)["bot"] = button_pressed
	if global.sound: sfx.play()

func _on_player_name_text_entered(new_text, extra_arg_0):
	GameState.getPlayerByIdentifier(extra_arg_0)["name"] = new_text


func _on_add_pressed():
	var player = GameState.addPlayer()
	
	var panel = PlayerPanel.instance()
	panel.player = player
	panel.update()
	players_container.add_child(panel)
	if global.sound: sfx.play()
		
func _on_tutorial_pressed():
	tutorial_popup.popup()


func _on_close_pressed():
	tutorial_popup.visible = false

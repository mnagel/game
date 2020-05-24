extends Control

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
		var tmp = global.sound
		global.sound = false
		_on_add_pressed()
		_on_add_pressed()
		global.sound = tmp

func _process(_delta):
	var players = players_container.get_children()
	if len(players) < 2: # minimum number of players
		lp_msg.visible = true
	else:
		lp_msg.visible = false


# Signals
func _on_play_pressed():
	if global.sound: sfx.play()
	var players = $scroll/container.get_children()
	if len(players) < 2: # minimum number of players
		pass
	else:
		get_tree().change_scene("res://scenes/main.tscn")


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

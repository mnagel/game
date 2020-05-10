extends Node

# Player's stuff
var players = {}
var available_colors = ["fuchsia", "cyan", "lime", "orange"]
var highlighted = ""

var rng = RandomNumberGenerator.new()

var current_round = 1

# Buggle related stuff
var buggle_speed = 5
var connection_line_width = 7

var margin = 5

# Viewport limits
var min_limits = Vector2(10, 10)
var max_limits = Vector2(440, 440)

# Anti things xD
var antialiasing = true

# Sfx stuff
var sound = true

const connection_maxlength = 50 # maximum distance between slimed buggles
const safezone_radius = 90  # minimum distance between the primary and secondary slimes


func getPlayerByIndex(player_index):
	if player_index >= 0 and player_index < players.size():
		return global.players[global.players.keys()[player_index]]
	else:
		# Should never happen
		push_error("Invalid index passed to getPlayerByIndex")
		return null

func getPlayerByIdentifier(player_identifier):
	if player_identifier in global.players.keys():
		return global.players[player_identifier]
	else:
		# Should never happen
		push_error("Invalid identifier passed to getPlayerByIdentifier")
		return

func setPlayer(dict):
	global.players[dict["identifier"]] = dict

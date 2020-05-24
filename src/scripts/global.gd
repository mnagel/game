extends Node

# Player's stuff
var players = {}
var available_colors = [
	"red",
	"green",
	"blue",
	"yellow",
	"deeppink",
	"cyan",
	"greenyellow",
	"deepskyblue", 
	"indigo", 
	"aqua", 
	"orange",
	"lime",
	"magenta",
	"orange",
	"orangered",
	"tomato",
	"yellowgreen"
	]
var highlighted = ""

var rng = RandomNumberGenerator.new()

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

# Rounds 
const num_rounds = 4
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

func rankPlayers():
	var player_identifiers = players.keys()
	player_identifiers.sort_custom(self, "comparePlayers")
	return player_identifiers

func comparePlayers(player_identifier_a, player_identifier_b):
	return getPlayerByIdentifier(player_identifier_a)["total_score"] > getPlayerByIdentifier(player_identifier_b)["total_score"]

func getRandomPosition():
	var rx = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	var ry = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	var pos = Vector2(rx, ry)
	return pos

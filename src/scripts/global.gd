extends Node

# Player's stuff
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
export (int) var buggles_count = 60

var margin = 5

# Viewport limits
var min_limits = Vector2(10, 10)
var max_limits = Vector2(440, 440)

# Anti things xD
var antialiasing = true

# Sfx stuff
var sound = true

# Rounds 
const num_rounds = 1
const connection_maxlength = 50 # maximum distance between slimed buggles
const safezone_radius = 90  # minimum distance between the primary and secondary slimes


func getRandomPosition():
	var rx = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	var ry = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	var pos = Vector2(rx, ry)
	return pos

extends Node


# Player's stuff
var players = {"red": {"name": "Red", "score": 0, "total_score": 0, "bot": false},
                "blue": {"name": "Blue", "score": 0, "total_score": 0, "bot": true}}
var current_player = 1
var num_players = 2
var highlighted = "red"
var highest_score = 1
var order = []
var colors = ["red", "blue", "green", "yellow"]


var rng = RandomNumberGenerator.new()

# Buggle related stuff
var buggle_speed = 5
var connection_line_width = 7



var margin = 5

var tutorial = true

# Viewport limits
var min_limits = Vector2(10, 10)
var max_limits = Vector2(440, 440)

# Anti things xD
var antialiasing = true
var anticheat = false

# Sfx stuff
var sound = true

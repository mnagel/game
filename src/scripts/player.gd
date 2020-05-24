extends Node

var display_name = ""
var player_num = 0
var bot = false
var color = "none"

var total_score = 0
var score = 0

signal player_changed()

func update_score(round_score):
	score = round_score
	rset('score', score)

func update_total_score():
	total_score += score
	score = 0
	rset('score', score)
	rset('total_score', total_score)

func update_player():
	rset('display_name', display_name)
	rset('player_num', player_num)
	rset('bot', bot)
	rset('color', color)
	rpc("player_changed")

puppet func player_changed():
	emit_signal("player_changed")

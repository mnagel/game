extends Container

var color = "null"


func _process(delta):
	update()


func update():
	$full_round_progress.region_rect = Rect2(0, 0, float(160 * int($round_score.text) / 60.0), 8)
	$highlighted.visible = (global.highlighted == color)
	
	$player_name.text = global.players[color]["name"]
	$round_score.text = str("R", global.current_round, ": ", global.players[color]["score"])
	$total_score.text = str(global.players[color]["total_score"])
	if global.players[color]["bot"]:
		$avatar.texture = load("res://assets/avatars/bot-" + color + ".png")
	else:
		$avatar.texture = load("res://assets/avatars/human-" + color + ".png")
	$bot.visible = global.players[color]["bot"]

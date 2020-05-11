extends Container

var player_identifier = ""

func getPlayer():
	return global.getPlayerByIdentifier(player_identifier)


func _process(delta):
	var score = getPlayer()["score"]
	$full_round_progress.region_rect = Rect2(0, 0, float(160 * score / 60.0), 8)
	$highlighted.visible = (global.highlighted == player_identifier)
	update()


func update():
	$player_name.text = getPlayer()["name"]
	$round_score.text = str("R", global.current_round, ": ", getPlayer()["score"])
	$total_score.text = str(getPlayer()["total_score"])

	if getPlayer()["bot"]:
		$avatar.texture = load("res://assets/avatars/bot.png")
	else:
		$avatar.texture = load("res://assets/avatars/human.png")
	$avatar.modulate = ColorN(getPlayer()["color"])
	$bot.visible = getPlayer()["bot"]

extends Container

var State = enums.State

var player

func _process(delta):
	$full_round_progress.region_rect = Rect2(0, 0, float(160 * player.score / 60.0), 8)
	if GameState.state == State.allPick:
		$highlighted.visible = (player == GameState.getCurrentPlayer())
	else:
		$highlighted.visible = false
	update()


func update():
	$player_name.text = player.display_name
	$round_score.text = str("R", GameState.round_number, ": ", player.score)
	$total_score.text = str(player.total_score)

	if player.bot:
		$avatar.texture = load("res://assets/avatars/bot.png")
	else:
		$avatar.texture = load("res://assets/avatars/human.png")
	$avatar.modulate = player.color
	$bot.visible = player.bot

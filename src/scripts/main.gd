extends Node2D

# separates the phases of a round, i.e. primary and secondary slime core placement
var primary_core_phase = true

# Buggles movement
var connected_buggles = 0
var buggle = preload("res://scenes/buggle.tscn")
var pause_buggles = false
var buggles_nodes = []
var backup_buggles = []
export (int) var buggles_count = 60

# Players
var current_player = global.current_player
var num_players = global.num_players
var players = global.players
var turn_msg_displayed = false

# Rounds 
var current_round = 1
var num_rounds = 10

# Timers
onready var start_timer = $start_timer
onready var start_next_round_timer = $start_next_round_timer
onready var bot_thinking = $bot_thinking
onready var player_timer = $player_timer

# Other Nodes
onready var pause_btn = $panel/buttons/pause
onready var pause_scr = $paused
onready var sound_btn = $panel/buttons/sound
onready var messages_board = $messages
onready var player_timer_label = $player_timer_label
onready var winner_label = $gui/game_over/winner
onready var game_over_popup = $gui/game_over
onready var players_order = $gui/game_over/order
onready var round_label = $round
onready var players_board = $players_container
onready var round_anim_label = $round_anim_label
onready var animation_player = $anim
onready var manim = $manim
onready var mouse_pos_indicator = $mouse_pos
onready var timeout_popup = $timeout
onready var warn_player = $warn_player
onready var tutorial_popup = $tutorial

# Slimes
var slimecore = preload("res://scenes/slimecore.tscn")
var player_status = preload("res://scenes/player_status.tscn")
var slimes_nodes = []
var safe_zone = 90  # The minimum distance between the primary and 2nd slimes

# Viewport limits
var margin = global.margin
var min_limits = global.min_limits
var max_limits = global.max_limits

# Sfx
onready var sfx = $sfx
onready var round_sfx = $round_sfx
onready var game_over_sfx = $game_over_sfx
onready var bg_music = $bg_music

# Random number generator
var rng = global.rng

# Gameplay
var game_over = false
var tutorial = global.tutorial

# Functions
func putSlime(position):
	# position == null is used to trigger AI placement
	var instancedSlime = slimecore.instance()
	instancedSlime.primary = primary_core_phase

	if position == null:
		instancedSlime.position = getMidstPosition()+ getRandomPosition()*rng.randf_range(0.2, 0.5)
	else:
		instancedSlime.position = position

	# Safe zone
	for slime in slimes_nodes:
		if slime.primary and not primary_core_phase:
			
			var slimes_distance = slime.position - instancedSlime.position
			if slimes_distance.length() <= safe_zone:
				if position == null:  # Bot's turn
					# bot's will keep getting positions, till it find one, that is away 
					while slimes_distance.length() <= safe_zone:
						instancedSlime.position = getRandomPosition()
						slimes_distance = slime.position - instancedSlime.position
				# If very close: show a message and return
				else: # Human
					warnPlayer()
					showMessage("You can't input very close to the primary slime\n", true)
					return
	if global.sound:
		sfx.play()

	instancedSlime.color = players.keys()[current_player - 1]
	slimes_nodes.append(instancedSlime)
	add_child(instancedSlime)
	player_timer.stop()
	current_player += 1
	turn_msg_displayed = false

func warnPlayer(): # Warn the player visually
	warn_player.play("veryClose")

func BotDecision():
	putSlime(null)

func classifiePlayers():
	var posts = {}
	for i in range(0, num_players):
		var cur = players[players.keys()[i]]
		posts[str(cur["total_score"])] = players.keys()[i]
	var sorted_array = []
	for key in posts.keys():
		sorted_array.append(int(key))
	sorted_array.sort()
	sorted_array.invert()
	global.highest_score = sorted_array[0]
	var posts_dict = []
	for post in sorted_array:
		posts_dict.append(posts[str(post)])
	return posts_dict

func isPlayerBot(id):
	if players[players.keys()[id]]["bot"] == true:
		return true
	return false

func generateBuggles():
	buggles_nodes = []
	for _i in range(0, buggles_count):
		var instancedBuggle = buggle.instance()
		instancedBuggle.position = getRandomPosition()
		buggles_nodes.append(instancedBuggle)
		add_child(instancedBuggle)
	return

func resetBuggles():
	for node in buggles_nodes:
		node.reset()
		backup_buggles.append(node)
	for key in players.keys():
		players[key]["score"] = 0
	buggles_nodes = []

func removeSlimes():
	for node in slimes_nodes:
		remove_child(node)
	slimes_nodes = []

func getRandomPosition():
	rng.randomize()
	var rx = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	rng.randomize()
	var ry = rng.randi_range(min_limits.x + margin * 2, max_limits.x - margin * 2)
	var pos = Vector2(rx, ry)
	return pos

func resetScore():
	for key in global.players.keys():
		global.players[key]["total_score"] = 0
		global.players[key]["score"] = 0

func getMidstPosition():
	var pos = Vector2(0, 0)
	for node in buggles_nodes:
		pos += node.position
	pos = pos / buggles_nodes.size()
	return pos

func showMessage(msg, clear = false):
	if clear:
		messages_board.text = ""
	messages_board.text = msg + "\n"
	return

# Builtin
func _process(_delta):
	if connected_buggles >= buggles_count and current_round <= num_rounds:
		connected_buggles = 0
		if len(buggles_nodes):
			pause_buggles = true
		else:
			# New round
			if start_next_round_timer.is_stopped() and current_round < num_rounds:
				showMessage("Reflect upon your actions.", true)
				start_next_round_timer.start()
			else:  # Game Over`
				# Save score
				for key in players:
					players[key]["total_score"] += players[key]["score"]
					players[key]["score"] = 0  # Reset round score
				game_over = true

	# Hide slimes while inputing to prevent cheating
	for slime in slimes_nodes:
		if slime.primary:
			slime.visible = (not pause_buggles) or (not primary_core_phase)
		else:  # the secondary slimes
			slime.visible = (not pause_buggles)

	# Handle turns, buggles etc
	if pause_buggles:
		# Clear message box
		if not turn_msg_displayed: showMessage("id128736 should not happen", true)
		# Start countdown
		if player_timer.is_stopped():
			player_timer.start()
		# Update countdown timer's label
		else:
			player_timer_label.text = str(int(player_timer.time_left))
		if current_player <= num_players:  # If all the players haven't played yet
			# Highlight the current player
			global.highlighted = players.keys()[current_player - 1]
			# If a human is playing
			if not isPlayerBot(current_player - 1):
				if primary_core_phase:
					if not turn_msg_displayed:
						showMessage("Click somewhere to input primary slime core")
						turn_msg_displayed = true
				else:
					if not turn_msg_displayed:
						showMessage("Click somewhere to input secondary slime core")
						turn_msg_displayed = true
			# Bot thinking delay; a random delay
			else:
				showMessage("[Bot] Thinking ...")
				# Bot thinking delay, a random delay
				if bot_thinking.is_stopped():
					bot_thinking.start(rng.randf_range(0.6, 1.8))

	# If nobody is playing, aka: buggles are moving
	else:
		# display reviewing message, only when there are slimes
		if slimes_nodes.size():
			if start_next_round_timer.is_stopped():
				showMessage("Reviewing slime activity ...", true)
			else:
				showMessage("Preparing next round. Reflect upon your actions.", true)
		else:
			showMessage("id210944 should not happen", true)
		player_timer.stop()
		global.highlighted = "none"  # It's no one's turn, when buggles are moving
		# To prevent countdown from showing 0 when nobody is playing
		player_timer_label.text = "25"
		turn_msg_displayed = false

	# If all players have played their roles
	if current_player > num_players:
		if len(buggles_nodes) and not primary_core_phase:  # if this is the secondary slime input
			showMessage("resetting now", true)
			resetBuggles()
		if primary_core_phase and slimes_nodes.size() != 0:  # If this is the primary slime input and all players have played, then move to 2nd slime input
			current_player = 1  # First player's turn
			primary_core_phase = false
		if slimes_nodes.size() != 0: 
			pause_buggles = false  # make buggles move
		else:
			# If timeout and nobody has played
			player_timer.stop()
			if not timeout_popup.visible: 
				timeout_popup.popup()

	if game_over:
		showMessage("Game Over!", true)
		if global.sound:
			game_over_sfx.play()
		bg_music.stop()
		classifiePlayers()
		winner_label.text = "Winner is " + global.players[global.order[0]]["name"]
		game_over_popup.popup()
		showMessage("Winner is " + global.players[global.order[0]]["name"])
		global.highlighted = global.order[0]
		for player in global.order:
			var ps = player_status.instance()
			ps.color = player
			ps.update()
			players_order.add_child(ps)
		set_process(false)

	# Update the round label
	round_label.text = str(current_round) + "/" + str(num_rounds)
	# Classifie the players according to their total score
	global.order = classifiePlayers()

func _input(event):
	if event is InputEventMouseButton and not get_tree().paused and not timeout_popup.visible:
		if event.is_pressed() and event.button_index == BUTTON_LEFT and pause_buggles:
			var mouse_pos = get_global_mouse_position()
			# If mouse input is inside of the playfield
			if (
				mouse_pos.x > min_limits.x
				and mouse_pos.y > min_limits.y
				and mouse_pos.x < max_limits.x
				and mouse_pos.y < max_limits.y
			):
				# If the player hasn't played yet, and is human
				if current_player <= num_players and not isPlayerBot(current_player - 1):
					putSlime(mouse_pos)

func _ready():
	if global.tutorial:
		tutorial_popup.popup()
		set_process(false)
	else:
		set_process(true)
		rng.randomize()
		generateBuggles()
		start_timer.connect("timeout", self, "on_start_timer_timeout")
		start_timer.start()
		game_over = false
		if global.sound:
			round_sfx.stream = load("res://assets/sound/round_" + str(current_round) +".wav")
			round_sfx.play()
		else:
			bg_music.stop()
		round_anim_label.text = "ROUND " + str(current_round)
		animation_player.play("round")
		if global.sound:
			sound_btn.text = "SOUND:ON"
		else:
			sound_btn.text = "SOUND:OFF"
		for key in players.keys():
			var instancedPlayerStatus = player_status.instance()
			instancedPlayerStatus.color = key
			instancedPlayerStatus.update()
			players_board.add_child(instancedPlayerStatus)

# Signals
func on_start_timer_timeout():
	# Stop buggles after an interval
	pause_buggles = not pause_buggles

func on_start_next_round_timer_timeout():
	current_round += 1
	# Save score to variable
	for key in players:
		players[key]["total_score"] += players[key]["score"]
		players[key]["score"] = 0
	# Clean
	for node in backup_buggles:
		remove_child(node)
	backup_buggles = []
	removeSlimes()
	# Build round
	generateBuggles()
	# Start the round
	primary_core_phase = true
	current_player = 1
	start_timer.start()
	round_anim_label.text = "ROUND " + str(current_round)
	animation_player.play("round")
	if global.sound:
		round_sfx.stream = load("res://assets/sound/round_" + str(current_round) +".wav")
		round_sfx.play()

func on_bot_thinking_timeout():
	BotDecision()
	player_timer.stop()

func on_player_timer_timeout():
	current_player += 1
	if pause_buggles:
		player_timer.start()
	elif slimes_nodes.size == 0:
		showMessage("Nobody played, moving on to next round")
		current_round += 1

func _on_restart_pressed():
	if get_tree().paused:
		get_tree().paused = false
	if pause_scr.visible:
		pause_scr.visible = false
	resetScore()
	return get_tree().reload_current_scene()

func _on_exit_pressed():
	if get_tree().paused:
		get_tree().paused = false
	return get_tree().change_scene("res://scenes/player-menu.tscn")

func _on_pause_pressed():
	get_tree().paused = not get_tree().paused
	player_timer.paused = not player_timer.paused and (not player_timer.is_stopped())
	pause_scr.visible = not pause_scr.visible
	if get_tree().paused:
		pause_btn.text = "RESUME"
	else:
		pause_btn.text = "PAUSE"

func _on_sound_pressed():
	global.sound = not global.sound
	if global.sound:
		bg_music.play()
		sound_btn.text = "SOUND:ON"
	else:
		sound_btn.text = "SOUND:OFF"
		bg_music.stop()

func _on_next_round_btn_pressed():
	timeout_popup.visible = false
	pause_buggles = false
	resetBuggles()
	start_timer.start()
	current_player = 1
	if not primary_core_phase:
		on_start_next_round_timer_timeout() # modern problems, require modern solutions xD
	primary_core_phase = false

func _on_play_btn_pressed():
	tutorial_popup.visible = false
	global.tutorial = false
	_on_restart_pressed()


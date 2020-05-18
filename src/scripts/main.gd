extends Node2D

# separates the phases of a round, i.e. primary and secondary slime core placement
var primary_core_phase = true

# Buggles movement
var connected_buggles = 0
var buggle = preload("res://scenes/buggle.tscn")
var pause_buggles = false
var state_exploding = false

# Players
var turn_msg_displayed = false
var order = []

# Rounds 
var num_rounds = 4

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


# Slimes
var slimecore = preload("res://scenes/slimecore.tscn")
var player_status = preload("res://scenes/player_status.tscn")

# Viewport limits
var margin = global.margin
var min_limits = global.min_limits
var max_limits = global.max_limits

# Sfx
onready var sfx = $sfx
onready var round_sfx = $round_sfx
onready var game_over_sfx = $game_over_sfx

# Random number generator
var rng = global.rng

# Gameplay
var game_over = false


func canPlaceCore(position):
	# secondary cores need to stay away from primary cores
	if not primary_core_phase:
		for slime in global.slimecores:
			if slime.primary:
				var slimes_distance = slime.position - position
				if slimes_distance.length() <= global.safezone_radius:
					return false
			else:
				# secondary cores may be closeby, because their position is not known to the player
				continue
	return true


# Functions
func tryPutCore(position):
	if not canPlaceCore(position):
		return false

	var instancedSlime = slimecore.instance()
	instancedSlime.player_identifier = global.getPlayerByIndex(global.current_player_index)["identifier"]
	instancedSlime.set_safe_zone(global.safezone_radius)
	instancedSlime.primary = primary_core_phase
	instancedSlime.position = position

	# core can actually be put here
	if global.sound:
		sfx.play()

	global.slimecores.append(instancedSlime)
	add_child(instancedSlime)
	player_timer.stop()
	global.current_player_index += 1
	turn_msg_displayed = false
	return true

func warnPlayer(): # Warn the player visually
	warn_player.play("veryClose")

func showMessage(msg, clear = false):
	if clear:
		messages_board.text = ""
	messages_board.text = msg + "\n"
	return

# Builtin
func _process(_delta):
	if connected_buggles >= global.buggles_count and global.current_round <= num_rounds:
		connected_buggles = 0
		if len(global.buggles_nodes):
			pause_buggles = true
		else:
			# New round
			if start_next_round_timer.is_stopped() and global.current_round < num_rounds:
				showMessage("Reflect upon your actions.", true)
				start_next_round_timer.start()
			else:  # Game Over`
				# Save score
				for player in global.players.values():
					player["total_score"] += player["score"]
					player["score"] = 0  # Reset round score
				game_over = true

	# Hide slimes while inputing to prevent cheating
	for slime in global.slimecores:
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
		if global.current_player_index < len(global.players):  # If all the players haven't played yet
			# Highlight the current player
			global.highlighted = global.getPlayerByIndex(global.current_player_index)["identifier"]
			# If a human is playing
			if not global.isCurrentPlayerBot():
				if primary_core_phase:
					if not turn_msg_displayed:
						showMessage("Place your primary supernova")
						turn_msg_displayed = true
				else:
					if not turn_msg_displayed:
						showMessage("Place your secondary supernova")
						if global.sound:
							sfx.play()
						turn_msg_displayed = true
			else:
				showMessage("[Bot] Thinking ...")
				# Bot thinking delay, a random delay
				if bot_thinking.is_stopped():
					var bot_think_delay = rng.randf_range(0.6, 1.8)
					bot_think_delay = 0
					bot_thinking.start(bot_think_delay)

	# If nobody is playing, aka: buggles are moving
	else:
		state_exploding = true
		# display reviewing message, only when there are slimes
		if global.slimecores.size():
			if start_next_round_timer.is_stopped():
				showMessage("Watching the universe explode", true)
			else:
				showMessage("Preparing fresh universe. Reflect upon your actions.", true)
		else:
			showMessage("Watch the world go by.", true)
		player_timer.stop()
		global.highlighted = ""  # It's no one's turn, when buggles are moving
		# To prevent countdown from showing 0 when nobody is playing
		player_timer_label.text = "25"
		turn_msg_displayed = false

	# If all players have played their roles
	if global.current_player_index >= len(global.players):
		if len(global.buggles_nodes) and not primary_core_phase:  # if this is the secondary slime input
			showMessage("resetting now", true)
			global.resetBuggles()
		if primary_core_phase and global.slimecores.size() != 0:  # If this is the primary slime input and all players have played, then move to 2nd slime input
			global.current_player_index = 0  # First player's turn
			primary_core_phase = false
		if global.slimecores.size() != 0: 
			pause_buggles = false  # make buggles move
		else:
			# If timeout and nobody has played
			player_timer.stop()
			if not timeout_popup.visible: 
				timeout_popup.popup()

	if game_over:
		if global.sound:
			game_over_sfx.play()
		
		order = global.rankPlayers()
		winner_label.text = global.getPlayerByIdentifier(order[0])["name"] + " is the most shiny!"
		showMessage(global.getPlayerByIdentifier(order[0])["name"] + " is the most shiny!")
		game_over_popup.popup()
		global.highlighted = order[0]
		for player_identifier in order:
			var ps = player_status.instance()
			ps.player_identifier = player_identifier
			ps.update()
			players_order.add_child(ps)
		set_process(false)

	# Update the round label
	round_label.text = str(global.current_round) + "/" + str(num_rounds)
	# Classifie the players according to their total score
	order = global.rankPlayers()

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
				if global.current_player_index < len(global.players) and not global.isCurrentPlayerBot():
					if not tryPutCore(mouse_pos):
						warnPlayer()
						showMessage("Supernova overload. Explode elsewhere!\n", true)

func _ready():
	set_process(true)
	start_timer.connect("timeout", self, "on_start_timer_timeout")
	global.current_round = 0
	game_over = false
	for player_identifier in global.players.keys():
		var instancedPlayerStatus = player_status.instance()
		instancedPlayerStatus.player_identifier = player_identifier
		instancedPlayerStatus.update()
		players_board.add_child(instancedPlayerStatus)
	on_start_next_round_timer_timeout()

# Signals
func on_start_timer_timeout():
	# Stop buggles after an interval
	pause_buggles = not pause_buggles

func on_start_next_round_timer_timeout():
	state_exploding = false
	global.current_round += 1
	# Save score to variable
	for player in global.players.values():
		player["total_score"] += player["score"]
		player["score"] = 0
	# Clean
	global.removeBackupBuggles(self)
	global.removeSlimes(self)
	# Build round
	global.generateBuggles(self)
	# Start the round
	primary_core_phase = true
	global.current_player_index = 0
	start_timer.start()
	round_anim_label.text = "UNIVERSE " + str(global.current_round)
	animation_player.play("round")
	if global.sound:
		var sndfile = global.current_round
		if global.current_round > 10 or global.current_round == num_rounds:
			sndfile = 10 # play final round for last round and prevent bad access
		
		round_sfx.stream = load("res://assets/sound/round_" + str(sndfile) +".wav")
		round_sfx.play()

func on_bot_thinking_timeout():
	while true:	
		if tryPutCore(Bot.getBotLocationChoice(self, global.current_player_index)):
			break
		else:
			# position was illegal. try again
			continue
	player_timer.stop()

func on_player_timer_timeout():
	global.current_player_index += 1
	if pause_buggles:
		player_timer.start()
	elif global.slimecores.size == 0:
		showMessage("Nothing exploded, moving on to next universe...")
		global.current_round += 1

func _on_restart_pressed():
	if get_tree().paused:
		get_tree().paused = false
	if pause_scr.visible:
		pause_scr.visible = false
	global.resetScore()
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
		sound_btn.text = "SOUND:ON"
	else:
		sound_btn.text = "SOUND:OFF"

func _on_next_round_btn_pressed():
	timeout_popup.visible = false
	pause_buggles = false
	global.resetBuggles()
	start_timer.start()
	global.current_player_index = 0
	if not primary_core_phase:
		on_start_next_round_timer_timeout() # modern problems, require modern solutions xD
	primary_core_phase = false

func _on_play_btn_pressed():
	_on_restart_pressed()


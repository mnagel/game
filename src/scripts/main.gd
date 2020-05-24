extends Node2D

var state = GameState
var State = enums.State

# Buggles movement
var buggle = preload("res://scenes/buggle.tscn")
var slimecore = preload("res://scenes/slimecore.tscn")

var player_status = preload("res://scenes/player_status.tscn")

var allPick_playerindex = 0
var allPick_novaindex = 0

func isCurrentPlayerBot():
	return GameState.getCurrentPlayer().bot

# Timers
onready var start_timer = $start_timer
onready var start_next_round_timer = $start_next_round_timer
onready var player_timer = $player_timer

# Other Nodes
onready var pause_btn = $panel/buttons/pause
onready var pause_scr = $paused
onready var sound_btn = $panel/buttons/sound
onready var messages_board = $messages
onready var player_timer_label = $player_timer_label
onready var winner_label = $gui/game_over/winner
onready var game_over_popup = $gui/game_over
onready var player_ranking_ui = $gui/game_over/order
onready var round_label = $round
onready var players_board = $players_container
onready var round_anim_label = $round_anim_label
onready var animation_player = $anim
onready var manim = $manim
onready var mouse_pos_indicator = $mouse_pos
onready var timeout_popup = $timeout
onready var warn_player = $warn_player

# Sfx
onready var sfx = $sfx
onready var round_sfx = $round_sfx
onready var game_over_sfx = $game_over_sfx

func playerDone():
	# handle the transitioned-from player
	GameState.playerDone()
	allPick_playerindex += 1
	player_timer_label.text = "25"
	round_label.text = str(state.round_number) + "/" + str(global.num_rounds)
	
	if allPick_playerindex == GameState.getPlayerCount():
		print ("state machine: allPick_playerindex: proceed nova")
		allPick_novaindex += 1
		allPick_playerindex = 0
		transition(State.allPick, State.explosions)
	else:
		getOnePick()

func getOnePick():
	# handle the transitioned-to player
	if isCurrentPlayerBot():
		while true:
			if tryPutCore(Bot.getBotLocationChoice(self, allPick_playerindex)):
				break
			else:
				# position was illegal. try again
				continue
	else:
		player_timer.start()
		showMessage("Place your supernova")

func transition(from, to):
	# "from" is purely to check that we were actually in the state that we
	# were expecting, i.e. to force you to think.
	assert(state.state == from)
	print("state machine: %s -> %s.     universe:%s nova:%s player:%s" % 
		[state.StateToString(from), state.StateToString(to), state.round_number, allPick_novaindex, allPick_playerindex]
	)
	state.state = to

	match to:
		State.freefly:
			get_tree().paused = false
			allPick_playerindex = 0
			allPick_novaindex = 0
			state.round_number += 1
			# Save score to variable
			for player in GameState.getAllPlayers():
				player["total_score"] += player["score"]
				player["score"] = 0
			# Clean
			state.killBuggles(self)
			state.removeSlimes(self)
			# Build round
			state.generateBuggles(self)
	
			start_timer.start()
			round_anim_label.text = "UNIVERSE " + str(state.round_number)
			animation_player.play("round")
			if global.sound:
				var sndfile = state.round_number
				if state.round_number > 10 or state.round_number == global.num_rounds:
					sndfile = 10 # play final round for last round and prevent bad access
				
				round_sfx.stream = load("res://assets/sound/round_" + str(sndfile) +".wav")
				round_sfx.play()
		State.allPick:
			get_tree().paused = true
			getOnePick()
		State.explosions:
			state.reset_buggles()
			get_tree().paused = false
			showMessage("Watching the universe explode", true)
		State.afterExplosions:
			showMessage("Reflect upon your actions.", true)
			start_next_round_timer.start()
		State.gameOver:
			if global.sound:
				game_over_sfx.play()
				
			var ranked_players = GameState.getPlayersByScore()
			winner_label.text = ranked_players[0].display_name + " is the most shiny!"
			showMessage(ranked_players[0].display_name + " is the most shiny!")
			game_over_popup.popup()
			for player in ranked_players:
				var ps = player_status.instance()
				ps.player = player
				ps.update()
				player_ranking_ui.add_child(ps)
			set_process(false)

func canPlaceCore(position):
	# secondary cores need to stay away from primary cores
	for slime in state.slimecores:
		if allPick_novaindex > 0 and slime.primary: # FIXME check existing nova generation vs nova generation being placed
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

	# core can actually be put here
	if global.sound:
		sfx.play()
		
	var instancedSlime = slimecore.instance()
	instancedSlime.player = GameState.getCurrentPlayer()
	instancedSlime.set_safe_zone(global.safezone_radius)
	instancedSlime.primary = allPick_novaindex == 0
	instancedSlime.position = position
	state.slimecores.append(instancedSlime)
	add_child(instancedSlime)
	
	playerDone()
	return true

func warnPlayer(): # Warn the player visually
	warn_player.play("veryClose")

func showMessage(msg, clear = false):
	if clear:
		messages_board.text = ""
	messages_board.text = msg + "\n"
	return

func allStarsExploded(stars):
	for star in stars:
		if star.type == "buggle":
			return false
	return true

# simulate the game at 60 fps
# repeatedly called by the engine to proceed by game by delta
func _physics_process(_delta):
	if state.state == State.explosions:
		if allStarsExploded(state.buggles_nodes):
			if allPick_novaindex == 2:
				transition(State.explosions, State.afterExplosions)
			else:
				transition(State.explosions, State.allPick)
			
	if state.state == State.freefly:
			player_timer_label.text = str(int(player_timer.time_left))

func _input(event):
	if state.state == State.allPick and event.is_action_pressed('put_star'):
			if isCurrentPlayerBot():
					return
			
			# only inside play field	
			var mouse_pos = get_global_mouse_position()
			if ( false
				or mouse_pos.x < global.min_limits.x
				or mouse_pos.y < global.min_limits.y
				or mouse_pos.x > global.max_limits.x
				or mouse_pos.y > global.max_limits.y ):
				return
				
			if not tryPutCore(mouse_pos):
				warnPlayer()
				showMessage("Supernova overload. Explode elsewhere!\n", true)

func _ready():
	GameState.state = State.gameOver
	set_process(true)
	start_timer.connect("timeout", self, "on_start_timer_timeout")
	state.round_number = 0

	for player in GameState.getAllPlayers():
		var myPlayerPanel = player_status.instance()
		myPlayerPanel.player = player
		players_board.add_child(myPlayerPanel)
		myPlayerPanel.update()
	
	transition(State.gameOver, State.freefly)

# Signals
func on_start_timer_timeout():
	transition(State.freefly, State.allPick)

func on_start_next_round_timer_timeout():
	if state.round_number < global.num_rounds:
			transition(State.afterExplosions, State.freefly)
	else:
		for player in GameState.getAllPlayers():
			player["total_score"] += player["score"]
			player["score"] = 0  # Reset round score
		transition(State.afterExplosions, State.gameOver)

func on_player_timer_timeout():
	playerDone() # consider this player done

func _on_exit_pressed():
	state.killState(self)
	return get_tree().change_scene("res://scenes/player-menu.tscn")

func _on_sound_pressed():
	global.sound = not global.sound
	if global.sound:
		sound_btn.text = "SOUND:ON"
	else:
		sound_btn.text = "SOUND:OFF"

func _on_restart_pressed():
	state.killState(self)
	return get_tree().reload_current_scene()

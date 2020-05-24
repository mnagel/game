extends Node2D

var state = GameState
var State = enums.State
var Startype = enums.Startype

# Stargfxs movement
var stargfx = preload("res://scenes/stargfx.tscn")
var nova = preload("res://scenes/nova.tscn")

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
onready var warn_player = $warn_player

# Sfx
onready var sfx = $sfx
onready var round_sfx = $round_sfx
onready var game_over_sfx = $game_over_sfx

func playerDone():
	# handle the transitioned-from player
	player_timer_label.text = ""
	GameState.playerDone()
	allPick_playerindex += 1
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
			if tryPutNova(Bot.getBotLocationChoice(self, allPick_playerindex)):
				break
			else:
				# position was illegal. try again
				continue
	else:
		player_timer.start()
		player_timer_label.text = "25"
		showMessage("%s, please place your SuperNeoNova %d!" % [state.getCurrentPlayer().display_name, allPick_novaindex+1], true)


func animateRoundStart():
	round_anim_label.text = "UNIVERSE " + str(state.round_number)
	animation_player.play("round")
	
	if global.sound:
		var sndfile = state.round_number
		if state.round_number > 10 or state.round_number == global.num_rounds:
			sndfile = 10 # play final round for last round and prevent bad access
		
		round_sfx.stream = load("res://assets/sound/round_" + str(sndfile) +".wav")
		round_sfx.play()

func animateGameEnd(ranked_players):
	if global.sound:
		game_over_sfx.play()
	
	winner_label.text = ranked_players[0].display_name + " is the most shiny!"

	for player in ranked_players:
		var ps = player_status.instance()
		ps.player = player
		ps.update()
		player_ranking_ui.add_child(ps)

	game_over_popup.popup()


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
			showMessage("Watch the world go by...", true)
			
			allPick_playerindex = 0
			allPick_novaindex = 0
			state.round_number += 1
			round_label.text = str(state.round_number) + "/" + str(global.num_rounds)

			#func reset(scene, roundScore, totalScore, resetStars, removeStars, novas):
			state.reset(self, true, true, true, true, true)
			state.generateStars(self)

			start_timer.start()
			animateRoundStart()
		State.allPick:
			get_tree().paused = true
			showMessage("overwritten in getOnePick", true)
			getOnePick()
		State.explosions:
			get_tree().paused = false
			showMessage("Watch the universe explode...", true)

			#func reset(scene, roundScore, totalScore, resetStars, removeStars, novas):
			state.reset(self, true, false, true, false, false)
		State.afterExplosions:
			get_tree().paused = false
			showMessage("Reflect upon your actions.", true)

			for player in GameState.getAllPlayers():
				player["total_score"] += player["score"]
			start_next_round_timer.start()
		State.gameOver:
			get_tree().paused = false
			var ranked_players = GameState.getPlayersByScore()
			showMessage(ranked_players[0].display_name + " is the most shiny!")

			animateGameEnd(ranked_players)
			set_process(false)

func canPlaceNova(position):
	# secondary novas need to stay away from primary novas
	for nova in state.novas:
		if allPick_novaindex > 0 and nova.primary: # FIXME check existing nova generation vs nova generation being placed
			var distance = nova.position - position
			if distance.length() <= global.safezone_radius:
				return false
		else:
			# secondary novas may be closeby, because their position is not known to the player
			continue
	return true


# Functions
func tryPutNova(position):
	if not canPlaceNova(position):
		return false

	# nova can actually be put here
	if global.sound:
		sfx.play()
		
	var mynova = nova.instance()
	mynova.player = GameState.getCurrentPlayer()
	mynova.set_safe_zone(global.safezone_radius)
	mynova.primary = allPick_novaindex == 0
	mynova.position = position
	state.novas.append(mynova)
	add_child(mynova)
	
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
		if star.type == Startype.star:
			return false
	return true

# simulate the game at 60 fps
# repeatedly called by the engine to proceed by game by delta
func _physics_process(_delta):
	if state.state == State.explosions:
		if allStarsExploded(GameState.getAllStargfxs()):
			if allPick_novaindex == 2:
				transition(State.explosions, State.afterExplosions)
			else:
				transition(State.explosions, State.allPick)
			
	if state.state == State.allPick:
			player_timer_label.text = str(int(player_timer.time_left))

func _input(event):
	if state.state == State.allPick and event.is_action_pressed('put_nova'):
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
				
			if not tryPutNova(mouse_pos):
				warnPlayer()
				showMessage("Supernova overload. Explode elsewhere!\n", true)

func _ready():
	player_timer_label.text = ""
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
		transition(State.afterExplosions, State.gameOver)

func on_player_timer_timeout():
	playerDone() # consider this player done

func _on_exit_pressed():
	#func reset(scene, roundScore, totalScore, resetStars, removeStars, novas):
	state.reset(self, true, true, true, true, true)
	return get_tree().change_scene_to(load("res://scenes/player-menu.tscn"))

func _on_sound_pressed():
	global.sound = not global.sound
	if global.sound:
		sound_btn.text = "SOUND:ON"
	else:
		sound_btn.text = "SOUND:OFF"

func _on_restart_pressed():
	state.reset(self, true, true, true, true, true)
	return get_tree().reload_current_scene()

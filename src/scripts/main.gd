extends Node2D

# Buggles movement
var connected_buggles = 0
var buggle = preload("res://scenes/buggle.tscn")

enum State {
	idle,
	freefly,
	# must be triggered for each player, each turn
	allPick,
	explosions,
	afterExplosions,
	gameOver,
}

var hack_explosions_state = State.explosions

func statestring(s):
	if s == State.idle: return "idle"
	if s == State.freefly: return "freefly"
	if s == State.allPick: return "allPick"
	if s == State.explosions: return "explosions"
	if s == State.afterExplosions: return "afterExplosions"
	if s == State.gameOver: return "gameOver"
	return "unknown state"

# number of novas placed this turn
var allPick_innercount = 0
# number of turns where all players placed
var allPick_outercount = 0
onready var state = State.freefly

# Players
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

func transition(from, to):
	print("state machine: %s -> %s" % [statestring(from), statestring(to)])
	state = to
	
	if from == State.freefly:
		get_tree().paused = true
		
	
	if from == State.allPick:
		global.current_player_index += 1
		
		global.highlighted = ""
		player_timer_label.text = "25"
		round_label.text = str(global.current_round) + "/" + str(num_rounds)
		
		allPick_innercount += 1
		if allPick_innercount == len(global.players):
			print ("state machine: allPick_innercount: proceed turn")
			allPick_outercount += 1
			allPick_innercount = 0
			global.current_player_index = 0
			
			if allPick_outercount == 2:
				transition(State.allPick, State.explosions)
				return # all handled above
				
	
	if to == State.idle:
		pass
		
	if to == State.freefly:
		get_tree().paused = false
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

		start_timer.start()
		round_anim_label.text = "UNIVERSE " + str(global.current_round)
		animation_player.play("round")
		if global.sound:
			var sndfile = global.current_round
			if global.current_round > 10 or global.current_round == num_rounds:
				sndfile = 10 # play final round for last round and prevent bad access
			
			round_sfx.stream = load("res://assets/sound/round_" + str(sndfile) +".wav")
			round_sfx.play()

	# must be triggered for each player, each turn
	if to == State.allPick:
		player_timer.start()
		global.highlighted = global.getPlayerByIndex(global.current_player_index)["identifier"]
		if global.isCurrentPlayerBot():
			showMessage("[Bot] Thinking ...")
			var bot_think_delay = rng.randf_range(0.6, 1.8)
			bot_think_delay = 0 # slow thinking sucks
			bot_thinking.start(bot_think_delay)
		else:
			showMessage("Place your supernova")

	if to == State.explosions:
		get_tree().paused = false
		showMessage("Watching the universe explode", true)

	if to == State.afterExplosions:
		showMessage("Reflect upon your actions.", true)
		if global.current_round < num_rounds:
			start_next_round_timer.start()
		else:
			for player in global.players.values():
				player["total_score"] += player["score"]
				player["score"] = 0  # Reset round score
		
	if to == State.gameOver:
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

func canPlaceCore(position):
	# secondary cores need to stay away from primary cores
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

	# core can actually be put here
	if global.sound:
		sfx.play()
		
	var instancedSlime = slimecore.instance()
	instancedSlime.player_identifier = global.getPlayerByIndex(global.current_player_index)["identifier"]
	instancedSlime.set_safe_zone(global.safezone_radius)
	instancedSlime.primary = allPick_outercount == 0
	instancedSlime.position = position
	global.slimecores.append(instancedSlime)
	add_child(instancedSlime)
	
	transition(State.allPick, State.allPick)

func warnPlayer(): # Warn the player visually
	warn_player.play("veryClose")

func showMessage(msg, clear = false):
	if clear:
		messages_board.text = ""
	messages_board.text = msg + "\n"
	return

# simulate the game at 60 fps
# repeatedly called by the engine to proceed by game by delta
func _physics_process(_delta):
	if state == State.explosions:
		if connected_buggles >= global.buggles_count:
			transition(State.explosions, State.afterExplosions)
			
	if state == State.freefly:
			player_timer_label.text = str(int(player_timer.time_left))

func _input(event):
	if state == State.allPick and event.is_pressed() and event.button_index == BUTTON_LEFT:
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

	for player_identifier in global.players.keys():
		var instancedPlayerStatus = player_status.instance()
		instancedPlayerStatus.player_identifier = player_identifier
		instancedPlayerStatus.update()
		players_board.add_child(instancedPlayerStatus)
	
	transition(State.idle, State.freefly)

# Signals
func on_start_timer_timeout():
	transition(State.freefly, State.allPick)
	

func on_start_next_round_timer_timeout():
	transition(State.afterExplosions, State.freefly)

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
	transition(State.allPick, State.allPick) # consider this player done

func _on_exit_pressed():
	if get_tree().paused:
		get_tree().paused = false
	return get_tree().change_scene("res://scenes/player-menu.tscn")

func _on_sound_pressed():
	global.sound = not global.sound
	if global.sound:
		sound_btn.text = "SOUND:ON"
	else:
		sound_btn.text = "SOUND:OFF"

func _on_play_btn_pressed():
	print("fixme on play btn")


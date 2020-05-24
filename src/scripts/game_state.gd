extends Node

#var players = []  # TODO: reactivate
var round_number = 0

const freefly_timeout = 5
const turn_timeout = 15
const after_explosions_timeout = 7

const has_network = false

onready var players = Node.new()
onready var stars = Node.new()

func _ready():
	players.set_name("players")
	add_child(players)
	stars.set_name("stars")
	add_child(stars)

func sync_players():
	if has_network:
		# Iterate over all players and send their object state
		# TODO: Initial state
		for player in players.get_children():
			player.update_player()

func sync_stars():
	if has_network:
		# Iterate over all stars and send their object state
		# TODO: We really need to deal properly with initialization here
		pass
	
func sync_picks():
	if has_network:
		# Iterate over all picks and send them
		for player_id in novas:
			var nova = novas[player_id]
			pass
		pass

# Game:
#  - Synchronize players
#  - #Round start: send all initialized stars
#  - After freefly timeout: send "all pick"
#  - Every player sends their nova pick to the server
#  - After turn timeout or when all picks are in:
#    + Broadcast all picks
#    + Let them explode!
#  - After explosion timeout:
#    + Send scores to clients
#    + [Later: maybe send connections]
#  - Short after round timeout
#  - Increment round by one, goto round start
#  - End game, game over state

var State = enums.State

func StateToString(s):
	match s:
		State.idle:
			return "idle"
		State.gameOver:
			return "gameOver"
		State.freefly:
			return "freefly"
		State.allPick:
			return "allPick"
		State.explosions:
			return "explosions"
		State.afterExplosions:
			return "afterExplosions"
		_:
			return "unknown state"

onready var state = State.freefly

var timer = Timer.new()

func on_timer(new_state):
	state = new_state
	# TODO: server_tick()?

func on_round_end():
	round_number += 1
	state = State.freefly

func server_tick():
	match state:
		State.idle:
			# Do nothing
			pass
		State.freefly:
			sync_stars()
			rpc('client_state', State.freefly)
			timer = Timer.new()
			timer.connect('timeout', self, 'on_timer', State.allPick)
			timer.start(freefly_timeout)
			state = State.idle
		State.allPick:
			# Send all pick 
			rpc('client_state', State.allPick)
			# TODO: Implement checking if everyone has sent their state
			timer = Timer.new()
			timer.connect('timeout', self, 'on_timer', State.explosions)
			timer.start(turn_timeout)
			state = State.idle
		State.explosions:
			# Send picks of all players and start explosions
			sync_picks()
			rpc('client_state', State.explosions)
			# TODO: Check if explosions are done and then advance into afterExplosions
			# This also requires calculating the score and sending it off.
			state = State.idle
		State.afterExplosions:
			# Collect score for players and broadcast them
			sync_players()
			rpc('client_state', State.afterExplosions)
			timer = Timer.new()
			timer.connect('timeout', self, 'on_round_end')
			timer.start(after_explosions_timeout)
			state = State.idle

signal on_client_state_changed(state)
#	match state:
#		State.idle:
#			# Do nothing
#			pass
#		State.freefly:
#			# Let the stargfxs fly.
#			# TODO: Make we need lockstep synchronization.
#			pass
#		State.allpick:
#			# Start the picker in the UI.
#			pass
#		State.explosions:
#			# Make the stars explode.
#			pass
#		State.afterExplosions:
#			# Show the state after the explosion for a little longer.
#			pass

remotesync func client_state(state):
	if state != State.idle:
		emit_signal('on_client_state_changed', state)





var novas = []

var Star = preload('res://scenes/star.tscn')
var Stargfx = preload('res://scenes/stargfx.tscn')

onready var stargfxs_root = Node.new()

func reset_stargfxs():
	for stargfx in stargfxs_root.get_children():
		stargfx.reset(self)

func generateStargfxs(scene):
	stargfxs_root = Node.new()
	scene.add_child(stargfxs_root)
	for _i in range(0, global.stargfxs_count):
		var star = Star.instance()
		star.set_name(String(_i))
		star.init(global.getRandomPosition(), global.getRandomSpeed())
		stars.add_child(star)
		var instancedStargfx = Stargfx.instance()
		instancedStargfx.set_name(String(_i))
		instancedStargfx.init(star)
		instancedStargfx.get_node("donut-std-1").rotation_degrees = global.rng.randi_range(0, 360)
		stargfxs_root.add_child(instancedStargfx)

func killState(scene):
	killStargfxs(scene)
	removeNovas(scene)
	resetScore()

func killStargfxs(scene):
	for stargfx in stargfxs_root.get_children():
		stargfxs_root.remove_child(stargfx)
	scene.remove_child(stargfxs_root)
	for star in stars.get_children():
		stars.remove_child(star)

func removeNovas(scene):
	for node in novas:
		scene.remove_child(node)
	novas = []

func resetScore():
	for player in GameState.getAllPlayers():
		player.total_score = 0
		player.score = 0
		if has_network:
			player.update_player()


var Player = preload('res://scenes/player.tscn')
var currentPlayerIndex = 0

func playerDone():
	currentPlayerIndex += 1
	if currentPlayerIndex == getPlayerCount():
		currentPlayerIndex = 0

func getPlayerCount():
	return len(players.get_children())

func getCurrentPlayer():
	return players.get_children()[currentPlayerIndex]

func getAllPlayers():
	return players.get_children()
	
func getPlayersByScore():
	var ps = getAllPlayers()
	ps.sort_custom(self, "byScore")
	return ps 

func byScore(p1, p2):
	return p1.total_score > p2.total_score

func addPlayer():
	var player = Player.instance()
	player.display_name = global.available_names[global.rng.randi() % global.available_names.size()]
	player.color = ColorN(global.available_colors[global.rng.randi() % global.available_colors.size()])
	players.add_child(player)
	sync_players()
	return player
	
func delPlayer(player):
	players.remove_child(player)
	sync_players()

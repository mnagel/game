extends Node

#var players = []  # TODO: reactivate
var round_number = 0

var stars = []

# Player ID -> [nova]
var novas = {}

const freefly_timeout = 5
const turn_timeout = 15
const after_explosions_timeout = 7

onready var players = Node.new()

func _ready():
	players.set_name("players")
	add_child(players)

func sync_players():
	# Iterate over all players and send their object state
	# TODO: Initial state
	for player in players:
		player.update_player()

func sync_stars():
	# Iterate over all stars and send their object state
	# TODO: We really need to deal properly with initialization here
	pass
	
func sync_picks():
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
#			# Let the buggles fly.
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





var buggles_nodes = []
var slimecores = []

var Buggle = preload('res://scenes/buggle.tscn')

func reset_buggles():
	for buggle in buggles_nodes:
		buggle.reset(self)

func generateBuggles(scene):
	buggles_nodes = []
	for _i in range(0, global.buggles_count):
		var rng = global.rng # FIXME kill this. handle pos+speed the same way
		var rny = rng.randf_range(-1.0, +1.0)
		var rnx = rng.randf_range(-1.0, +1.0)
		var speed = Vector2(rnx, rny) * global.buggle_speed

		var instancedBuggle = Buggle.instance()
		instancedBuggle.init(global.getRandomPosition(), speed)
		instancedBuggle.get_node("donut-std-1").rotation_degrees = rng.randi_range(0, 360)
		buggles_nodes.append(instancedBuggle)
		scene.add_child(instancedBuggle)
	return
	
func killState(scene):
	killBuggles(scene)
	removeSlimes(scene)
	resetScore()

func killBuggles(scene):
	for node in buggles_nodes:
		scene.remove_child(node)
	buggles_nodes = []

func removeSlimes(scene):
	for node in slimecores:
		scene.remove_child(node)
	slimecores = []

func resetScore():
	for player in GameState.getAllPlayers():
		player.total_score = 0
		player.score = 0


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
	player.name = global.available_names[global.rng.randi() % global.available_names.size()]
	player.color = ColorN(global.available_colors[global.rng.randi() % global.available_colors.size()])
	players.add_child(player)
	return player
	
func delPlayer(player):
	players.remove_child(player)

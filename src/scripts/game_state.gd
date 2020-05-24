extends Node

class_name GameState

var players = []
var round_number = 1

var stars = []

# Player ID -> [nova]
var novas = {}

const freefly_timeout = 5
const turn_timeout = 15
const after_explosions_timeout = 7

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

enum State {
	idle,
	gameOver,  # XXX?!
	freefly,
	allPick,
	explosions,
	afterExplosions,
}

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

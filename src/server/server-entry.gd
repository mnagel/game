extends Node

const SERVER_PORT := 3333
const MAX_CLIENTS := 25

def _player_connected(id):
	# Purely informational console output.
	print("Player connected: " + str(id))

# Open the port for listening, then open up a lobby.
func _ready():
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(SERVER_PORT, MAX_CLIENTS)
	if result == OK:
		get_tree().set_network_peer(peer)
		get_tree().connect("network_peer_connected", self, "_player_connected")
		print("Server started.")
		get_tree().change_scene("res://server/lobby/server-lobby.tscn")
		return true
	else:
		print("Failed to start server: %d" % result)
		return false

extends Node

# Protocol:
#  - Client sends "on_register_self" with its player ID and name (connection
#    event alone is not doing anything)
#  - Clients receive "on_register_player" to get informed about the details
#    of each player.
#  - Clients need to receive "on_unregister_player" to drop information about
#    a player. (Emitted on connection disconnect event.)

var players = {}

remote func on_register_self(newPlayerId, newPlayerName):
	self.players[newPlayerId] = newPlayerName
	for playerId in self.players:
		# Send new player to existing players
		rpc_id(playerId, "on_register_player", newPlayerId, newPlayerName)
		if playerId != newPlayerId:
			# Send existing players to new player
			rpc_id(newPlayerId, "on_register_player", playerId,
				self.players[playerId])

func unregister_player(playerId):
	for id in self.players:
		rpc_id(id, "on_unregister_player", playerId)

func _ready():
	get_tree().connect("network_peer_disconnected", self, "unregister_player")
	return true

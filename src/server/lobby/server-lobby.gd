extends Node

# Protocol:
#  - Client sends "on_register_self" with its player ID and name (connection
#    event alone is not doing anything)
#  - Clients receive "on_register_player" to get informed about the details
#    of each player.
#  - Clients need to receive "on_unregister_player" to drop information about
#    a player. (Emitted on connection disconnect event.)
#  - Lobbies are created on client request through "on_create_lobby" and are
#    broadcasted as "on_update_lobby" to all clients with the current list
#    of players. Empty lobbies should be discarded client-side.

var players = {}
var lobbyCounter = 0

remote func on_register_self(newPlayerName):
	var newPlayerId = get_tree().get_rpc_sender_id()
	self.players[newPlayerId] = newPlayerName
	for playerId in self.players:
		# Send new player to existing players
		rpc_id(playerId, "on_register_player", newPlayerId, newPlayerName)
		if playerId != newPlayerId:
			# Send existing players to new player
			rpc_id(newPlayerId, "on_register_player", playerId,
				self.players[playerId])

func unregister_player(id):
	for playerId in self.players:
		rpc_id(id, "on_unregister_player", playerId)

remote func on_create_lobby():
	var id = get_tree().get_rpc_sender_id()
	lobbyCounter += 1
	var lobbyId = lobbyCounter
	self.lobbies[lobbyId] = [id]
	rpc("on_update_lobby", lobbyId, self.lobbies[lobbyId])

remote func on_join_lobby(lobbyId):
	var id = get_tree().get_rpc_sender_id()
	if !self.lobbies[lobbyId].has(id):
		self.lobbies[lobbyId].append(id)
		rpc("on_update_lobby", lobbyId, self.lobbies[lobbyId])

remote func on_leave_lobby(lobbyId):
	var id = get_tree().get_rpc_sender_id()
	if self.lobbies[lobbyId].has(id):
		self.lobbies[lobbyId].erase(id)
		rpc("on_update_lobby", lobbyId, self.lobbies[lobbyId])

func _ready():
	get_tree().connect("network_peer_disconnected", self, "unregister_player")
	return true

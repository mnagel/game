extends Node

# Entry point for the whole app
# Determine the type of app this is, and load the entry point for that type
func _ready():
	print("Application started")
	global.rng.randomize()
	# var menu = "res://client/client-entry.tscn"
	var menu = "res://scenes/player-menu.tscn"
	if OS.has_feature("server"):
		print("Is server")
		get_tree().change_scene("res://server/server-entry.tscn")
	elif OS.has_feature("client"):
		print("Is client")
		get_tree().change_scene(menu)
	# When running from the editor, this is how we'll default to being a client
	else:
		print("Could not detect application type! Defaulting to client.")
		get_tree().change_scene(menu)

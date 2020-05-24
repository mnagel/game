extends Node

func getBotLocationChoice(main, player_id):
	if player_id != 0:
		return getMnagelBotLocationChoice(main, player_id, player_id * 20 + 20)
	else:
		return getMidstPosition(GameState.stargfxs_root.get_children()) + global.getRandomPosition() * global.rng.randf_range(0.2, 0.5)

func getMidstPosition(stargfxs_nodes):
	var pos = Vector2(0, 0)
	for node in stargfxs_nodes:
		pos += node.position
	pos = pos / stargfxs_nodes.size()
	return pos

func getMnagelBotLocationChoice(main, player_id, perc):
	var state = main.state
	var best_score_1 = 0 # in connection reach
	var best_score_2 = 0 # in safe reach
	var best_score_3 = 0 # other
	var best_node = GameState.stargfxs_root.get_children()[0]
	
	for pivot in GameState.stargfxs_root.get_children():
		# only consider outside of safe zones
		if not main.canPlaceNova(pivot.position):
			continue
			
		# we need some non-determinism to make multiple instances of the bot feasible
		if global.rng.randi_range(0, 100) > perc:
			continue # disregard node for choice 
		
		var pivot_score_1 = 0
		var pivot_score_2 = 0
		var pivot_score_3 = 0
		for other in GameState.stargfxs_root.get_children():
			# we need some non-determinism to make multiple instances of the bot feasible
			if global.rng.randi_range(0, 100) > perc:
				continue # disregard node for scoring 
			
			var distance = (pivot.position - other.position).length()
			if distance <= global.connection_maxlength:
				pivot_score_1 += 1
			if distance <= global.safezone_radius:
				pivot_score_2 += 1
			else:
				pivot_score_3 += 1 / pow(distance/global.connection_maxlength, 1.9)
		if pivot_score_1 + pivot_score_2 + pivot_score_3 >= best_score_1 + best_score_2 + best_score_3:
			best_score_1 = pivot_score_1
			best_score_2 = pivot_score_2
			best_score_3 = pivot_score_3
			best_node = pivot
	
	print("MNA bot (%d) acting for player %s, winning score %.1f+%.1f+%.1f"  
	% [perc, GameState.getCurrentPlayer(), best_score_1, best_score_2, best_score_3] 
	)
	return best_node.position

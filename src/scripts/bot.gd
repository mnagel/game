extends Node

# Random number generator
var rng = global.rng

func getBotLocationChoice(main, player_id):
	if player_id != 0:
		return getMnagelBotLocationChoice(main, player_id, player_id * 20 + 20)
	else:
		return getMidstPosition(global.buggles_nodes) + global.getRandomPosition() * rng.randf_range(0.2, 0.5)

func getMidstPosition(buggles_nodes):
	var pos = Vector2(0, 0)
	for node in buggles_nodes:
		pos += node.position
	pos = pos / buggles_nodes.size()
	return pos

func getMnagelBotLocationChoice(main, player_id, perc):	
	var best_score_1 = 0 # in connection reach
	var best_score_2 = 0 # in safe reach
	var best_score_3 = 0 # other
	var best_node = global.buggles_nodes[0]
	
	for pivot in global.buggles_nodes:
		# only consider outside of safe zones
		if not main.canPlaceCore(pivot.position):
			continue
			
		# we need some non-determinism to make multiple instances of the bot feasible
		if rng.randi_range(0, 100) > perc:
			continue # disregard node for choice 
		
		var pivot_score_1 = 0
		var pivot_score_2 = 0
		var pivot_score_3 = 0
		for other in global.buggles_nodes:
			# we need some non-determinism to make multiple instances of the bot feasible
			if rng.randi_range(0, 100) > perc:
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
	% [perc, global.getPlayerByIndex(player_id)["name"], best_score_1, best_score_2, best_score_3] 
	)
	return best_node.position

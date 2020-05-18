extends Area2D

var type = "buggle" # there are three types: nova, buggle, slimed-buggle
var player_identifier = ""
var color = null
var speed = global.buggle_speed
var parent = null  # star/nova one hop towards the nova
var distance = 0 # distance between this buggle and the core, in "hops"
var connection = null # star/nova one hop towards the nova

var direction = Vector2(0, 0)

# Viewport limits
var min_limits = global.min_limits
var max_limits = global.max_limits
var margin = global.margin

# vfx and sfx nodes
onready var donut = $donut
onready var sfx = $sfx
onready var explosion = $explosion


# collission detection for the sliming
func on_area_entered(who):
	if not get_parent().state_exploding: # TODO: get /main/ and the game state properly
		return
	
	var candidates = []
	
	# get all candidate areas
	for area in get_overlapping_areas():
		if area.type == "nova" or area.type == "slimed-buggle":
			candidates.append(area)
	if candidates.empty():
		return
	
	# chose the closest candidate area
	var best = candidates[0]
	for candidate in candidates:
		if (candidate.position - position).length() < (best.position - position).length():
			best = candidate
	
	if (best.position - position).length() < global.connection_maxlength:
		# connect to best
		parent = best
		color = parent.color
		distance = parent.distance + 1
		player_identifier = parent.player_identifier
		
		# set some own stats
		type = "slimed-buggle"

		connection = Line2D.new()
		# the position of parent
		connection.add_point(parent.position - position)  
		# this buggles's position
		connection.add_point(Vector2(0, 0))  
		connection.default_color = parent.color
		connection.antialiased = global.antialiasing
		connection.width = 100 / (distance + 10)
		connection.z_index = -1
		add_child(connection)

		# Buggle outline
		donut.visible = true
		donut.modulate = color
		
		# Explosion
		explosion.emitting = true
		explosion.process_material.color_ramp.gradient.set_color(0, color)
		explosion.process_material.color_ramp.gradient.set_color(1, color)
		
		# Sound effects
		if global.sound:
			sfx.pitch_scale = clamp(float(distance) - 1, 0.5, 3.0)
			sfx.play()
		
		# Scores
		global.getPlayerByIdentifier(player_identifier)["score"] += 1
		get_parent().connected_buggles += 1



func reset():
	type = "buggle" # there are three types: nova, buggle, slimed-buggle
	player_identifier = ""
	color = null
	speed = global.buggle_speed
	parent = null  # star/nova one hop towards the nova
	distance = 0 # distance between this buggle and the core, in "hops"
	connection = null # star/nova one hop towards the nova
	remove_child(connection)
	
	donut.visible = false
	
func _ready():
	var rng = global.rng # FIXME kill this. handle pos+speed the same way
	var rny = rng.randf_range(-100.0, 100.0)
	var rnx = rng.randf_range(-100.0, 100.0)
	direction = Vector2(rnx, rny)
	direction = direction.normalized()
	connect("area_entered", self, "on_area_entered")

	# Allow different gradients per boggle (actually only needed per player but whatever)
	explosion.process_material = explosion.process_material.duplicate()
	explosion.process_material.color_ramp = explosion.process_material.color_ramp.duplicate()
	explosion.process_material.color_ramp.gradient = explosion.process_material.color_ramp.gradient.duplicate()

func _physics_process(delta):
	# check if moving individually, and as all buggles
	if type == "buggle" and not get_parent().pause_buggles:  
		if (position.x <= min_limits.x + margin) or (position.x >= max_limits.x - margin):
			direction.x = -direction.x
		if position.y <= min_limits.y + margin or position.y >= max_limits.y - margin:
			direction.y = -direction.y
		position += direction * speed

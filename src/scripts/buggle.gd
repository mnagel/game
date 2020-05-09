extends Area2D

var type = "buggle" # there are three types: slime, buggle, slimed-buggle
var color = "white"  # default color
var moving = true
var speed = global.buggle_speed
var parent = null  # used to know the slime core
var direction = Vector2(0, 0)
var distance = 0 # distance between this buggle and the core, in buggles unit xD
var connections = 0
var connection = null
var line_width = global.connection_line_width


# Viewport limits
var min_limits = global.min_limits
var max_limits = global.max_limits
var margin = global.margin

# vfx and sfx nodes
onready var donut = $donut
onready var sfx = $sfx
onready var explosion = $explosion

# Random number generator
var rng = global.rng


# beta
var num_slimes = 0
var max_slimes = 4
var slimes_queue = []
var uniq_slimes = {}
var safe_zone = 50

func rand_choose(lst):
	return lst[rng.randi_range(0, lst.size()-1)]

# where the magic happens
func on_area_entered(area):
	for _area in get_overlapping_areas():
		if _area.type == "slime" or _area.type == "slimed-buggle":
			slimes_queue.append(_area)
	if slimes_queue.size(): area = rand_choose(slimes_queue)

	# chose the closest area 
	var tmp_arr = []
	var tmp_dict = {}
	for _area in slimes_queue:
		if _area.type == "slime":
			var _distance = _area.position - position
			tmp_arr.append(int(_distance.length()))
			tmp_dict[str(int(_distance.length()))] = _area

	# connect to the nearest
	tmp_arr.sort()
	if tmp_arr.size():
		area = tmp_dict[str(tmp_arr[0])]
	else:
		for _area in slimes_queue:
			if _area.type == "slimed-buggle":
				var _distance = _area.position - position
				tmp_arr.append(int(_distance.length()))
				tmp_dict[str(int(_distance.length()))] = _area
			tmp_arr.sort()
			if tmp_arr.size(): area = tmp_dict[str(tmp_arr[0])]

	if (
		(area.type == "slime" or area.type == "slimed-buggle")
		and (connections < 1)
		and not get_parent().pause_buggles
	):
		# if the area is far away, just ignore it 
		if area.type == "slimed-buggle":
			var _distance = position - area.position
			if _distance.length() > safe_zone:
				slimes_queue = []
				return
		# Let other buggles detect this slimed-buggle
		monitoring = true
		# Set the parent 
		parent = area
		distance = getSlimeDistance()
		# Stop the buggle from moving
		moving = false
		color = area.color
		connections += 1

		# Create a new connection
		var new_line = Line2D.new()
		# the position of core
		new_line.add_point(area.position - position)  
		# this buggles's position
		new_line.add_point(Vector2(0, 0))  
		# get the color from the connected object
		new_line.default_color = ColorN(area.color)
		# Antialiasing
		new_line.antialiased = global.antialiasing
		if distance <= 2:
			new_line.width = 10 / distance
		else:
			new_line.width = 20 / distance
		new_line.z_index = -1
		add_child(new_line)
		connection = new_line

		# Buggle outline
		donut.visible = true
		donut.modulate = ColorN(area.color)
		
		# Explosion
		explosion.emitting = true
		explosion.modulate = ColorN(area.color)
		
		# Sound effects
		if global.sound:
			sfx.pitch_scale = clamp(float(distance) - 1, 0.5, 3.0)
			sfx.play()
	
		# Scoring system
		var players = global.players
		if connections == 1:
			players[color].score += 1
			get_parent().connected_buggles += 1
		
		# set buggle to slimed
		type = "slimed-buggle"
	slimes_queue = []

func getSlimeDistance():
	# How much slimed-buggles are between this buggle and the slime core, ofc of the same color
	var d = 1
	if parent != null:
		if parent.type == "slime": return 1
		else:
			var pparent = parent.parent
			while 1:  
				d += 1
				if pparent.type != "slimed-buggle": break
				pparent = pparent.parent
	return d

func reset():
	color = "white"
	type = "buggle"
	donut.visible = false
	remove_child(connection)
	connections = 0
	connection = null
	moving = true
	distance = 0

func _ready():
	var rny = rng.randf_range(-100.0, 100.0)
	var rnx = rng.randf_range(-100.0, 100.0)
	direction = Vector2(rnx, rny)
	direction = direction.normalized()
	connect("area_entered", self, "on_area_entered")

func _physics_process(delta):
	# check if moving individually, and as all buggles
	if moving and not get_parent().pause_buggles:  
		if (position.x <= min_limits.x + margin) or (position.x >= max_limits.x - margin):
			direction.x = -direction.x
		if position.y <= min_limits.y + margin or position.y >= max_limits.y - margin:
			direction.y = -direction.y
		position += direction * speed

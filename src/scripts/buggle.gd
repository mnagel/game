extends Area2D

var State = enums.State

var type = "buggle" # there are three types: nova, buggle, slimed-buggle
var player_identifier = ""
var color = null
var speed = Vector2(0, 0)
var orig_position = null
var orig_speed = null
var parent = null  # star/nova one hop towards the nova
var distance = 0 # distance between this buggle and the core, in "hops"
var connection = null # star/nova one hop towards the nova

# Viewport limits
var min_limits = global.min_limits
var max_limits = global.max_limits
var margin = global.margin

# vfx and sfx nodes
onready var donut = $donut
onready var sfx = $sfx
onready var explosion = $explosion


# collision detection for the sliming
func on_area_entered(who):
	if self.type != "buggle":
		print("This should never happen :) exploding things that should not explode: %s by %s" % [self.type, who.type])
		return # do not connect things that should not be connected...
		pass
	
	var state = get_parent().state
	
	if not (state.state == State.explosions):
		return
	
	# get all candidate areas
	var candidates = []
	for area in state.buggles_nodes + state.slimecores: # FIXME why is overlapping areas not enough here...
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

		if self.connection != null:
			print("chaos")
		self.connection = Line2D.new()
		# the position of parent
		connection.add_point(parent.position - position)  
		# this buggles's position
		connection.add_point(Vector2(0, 0))  
		connection.default_color = parent.color
		connection.antialiased = global.antialiasing
		connection.width = 100 / (distance + 10)
		connection.z_index = -1
		self.add_child(connection)
		print("added connection %s %s" % [self, connection])

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

func reset(scene):
	if self.connection != null:
		print("rm connection %s %s" % [self, connection])
		self.remove_child(connection)
		connection.queue_free()
		connection = null # star/nova one hop towards the nova
	type = "buggle" # there are three types: nova, buggle, slimed-buggle
	player_identifier = ""
	color = null
	speed = orig_speed
	position = orig_position
	parent = null  # star/nova one hop towards the nova
	distance = 0 # distance between this buggle and the core, in "hops"
	
	donut.visible = false

func init(pos, vel):
	position = pos
	speed = vel
	
	orig_position = position
	orig_speed = speed

func _ready():
	connect("area_entered", self, "on_area_entered")

	# Allow different gradients per boggle (actually only needed per player but whatever)
	explosion.process_material = explosion.process_material.duplicate()
	explosion.process_material.color_ramp = explosion.process_material.color_ramp.duplicate()
	explosion.process_material.color_ramp.gradient = explosion.process_material.color_ramp.gradient.duplicate()

func _physics_process(delta):
	# check if moving individually, and as all buggles
	if type == "buggle":
		if (position.x <= min_limits.x + margin) or (position.x >= max_limits.x - margin):
			speed.x = -speed.x
		if position.y <= min_limits.y + margin or position.y >= max_limits.y - margin:
			speed.y = -speed.y
		position += speed

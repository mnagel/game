extends Area2D

var State = enums.State
var Startype = enums.Startype

var star = null

var type = Startype.star
var color = null
var player = null
var speed = Vector2(0, 0)
var parent = null  # star/nova one hop towards the nova
var distance = 0 # distance between this stargfx and the core, in "hops"
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
	if self.type != Startype.star:
		print("This should never happen :) exploding things that should not explode: %s by %s" % [self.type, who.type])
		return # do not connect things that should not be connected...
		pass
	
	if not (GameState.state == State.explosions):
		return
	
	# get all candidate areas
	var candidates = []
	for area in GameState.stargfxs_root.get_children() + GameState.novas: # FIXME why is overlapping areas not enough here...
		if area.type == Startype.nova or area.type == Startype.explodedstar:
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
		player = parent.player
		color = player.color
		distance = parent.distance + 1
		
		# set some own stats
		type = Startype.explodedstar

		if self.connection != null:
			print("chaos")
		self.connection = Line2D.new()
		# the position of parent
		connection.add_point(parent.position - position)  
		# this stargfxs's position
		connection.add_point(Vector2(0, 0))  
		connection.default_color = player.color
		connection.antialiased = global.antialiasing
		connection.width = 100 / (distance + 10)
		connection.z_index = -1
		self.add_child(connection)
		print("added connection %s %s" % [self, connection])

		# Stargfx outline
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
		player.score += 1

func reset(scene):
	if self.connection != null:
		print("rm connection %s %s" % [self, connection])
		self.remove_child(connection)
		connection.queue_free()
		connection = null # star/nova one hop towards the nova
	type = Startype.star
	player = null
	color = null
	position = star.position
	speed = star.velocity
	parent = null  # star/nova one hop towards the nova
	distance = 0 # distance between this stargfx and the core, in "hops"
	
	donut.visible = false

func init(star_):
	star = star_
	position = star.position
	speed = star.velocity

func _ready():
	connect("area_entered", self, "on_area_entered")

	# Allow different gradients per boggle (actually only needed per player but whatever)
	explosion.process_material = explosion.process_material.duplicate()
	explosion.process_material.color_ramp = explosion.process_material.color_ramp.duplicate()
	explosion.process_material.color_ramp.gradient = explosion.process_material.color_ramp.gradient.duplicate()

func _physics_process(delta):
	# check if moving individually, and as all stargfxs
	if type == Startype.star:
		if (position.x <= min_limits.x + margin) or (position.x >= max_limits.x - margin):
			speed.x = -speed.x
		if position.y <= min_limits.y + margin or position.y >= max_limits.y - margin:
			speed.y = -speed.y
		position += speed

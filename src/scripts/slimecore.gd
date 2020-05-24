extends Area2D

var type = "nova"
var primary = true
var player = null
var distance = 0


func _ready():
	$core.modulate = player.color

func set_safe_zone(safezone_radius):
	var spriteWidth = $safeZone.texture.get_width()
	var scalingFactor = float(safezone_radius * 2) / spriteWidth
	$safeZone.scale = Vector2(scalingFactor, scalingFactor)

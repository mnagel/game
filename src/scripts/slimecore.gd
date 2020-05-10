extends Area2D

var type = "slime"
var primary = true
var player_identifier = ""


func _ready():
	$core.modulate = Color(ColorN(global.getPlayerByIdentifier(player_identifier)["color"]))

func set_safe_zone(safezone_radius):
	var spriteWidth = $safeZone.texture.get_width()
	var scalingFactor = float(safezone_radius * 2) / spriteWidth
	$safeZone.scale = Vector2(scalingFactor, scalingFactor)

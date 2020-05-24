extends Area2D

var type = "nova"
var primary = true
var player_identifier = ""
var color = null
var distance = 0


func _ready():
	color = Color(ColorN(GameState.getPlayerByIdentifier(player_identifier)["color"]))
	$core.modulate = color

func set_safe_zone(safezone_radius):
	var spriteWidth = $safeZone.texture.get_width()
	var scalingFactor = float(safezone_radius * 2) / spriteWidth
	$safeZone.scale = Vector2(scalingFactor, scalingFactor)

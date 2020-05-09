extends Area2D

var type = "slime"
var primary = true
export (String, "red", "blue", "green", "yellow") var color = "red"


func _ready():
	$core.modulate = Color(ColorN(color))

func set_safe_zone(safe_zone):
	var spriteWidth = $safeZone.texture.get_width()
	var scalingFactor = float(safe_zone * 2) / spriteWidth
	$safeZone.scale = Vector2(scalingFactor, scalingFactor)

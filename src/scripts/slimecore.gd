extends Area2D

var type = "slime"
var primary = true
export (String, "red", "blue", "green", "yellow") var color = "red"


func _ready():
	$core.modulate = Color(ColorN(color))

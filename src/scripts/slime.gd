extends Area2D

var type = "slime"
var half = false # the secondary core
export (String, "red", "blue", "green", "yellow") var color = "red"


func _ready():
	$core.modulate = Color(ColorN(color))


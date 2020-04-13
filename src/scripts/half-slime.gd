extends Area2D

var type = "slime"
var half = true # if true, then this is the primary core
export (String, "red", "blue", "green", "yellow") var color = "red"


func _ready():
	$core.modulate = Color(ColorN(color))

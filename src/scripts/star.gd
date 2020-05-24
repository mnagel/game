extends Node

var position = Vector2(0, 0)
var velocity = Vector2(0, 0)

signal star_changed()

func init(pos, velo):
	position = pos
	velocity = velo

func update_star():
	rset('position', position)
	rset('velocity', velocity)
	rpc('star_changed')

puppet func star_changed():
	emit_signal('star_changed')

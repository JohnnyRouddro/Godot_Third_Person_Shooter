extends Control

var pos_x = 15

func fire(speed):
	for line in $reticle/lines.get_children():
		line.get_node("anim").playback_speed = speed
		line.get_node("anim").stop()
		line.get_node("anim").play("fire")
		pass
	pass

func _process(delta):
	for line in $reticle/lines.get_children():
		line.get_node("line_base").position.x = lerp(line.get_node("line_base").position.x, pos_x, delta * 12)

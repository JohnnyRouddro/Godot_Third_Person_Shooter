extends Control

onready var cam = get_node("../Camroot")

var current_item = -1

var time_scale_target = 1
var interpolation = 1

func _ready():
	hide()
	
func _input(event):
	if event.is_action_pressed("radial_menu"):
		$AnimationPlayer.play("zoom")
		
		time_scale_target = 0
		interpolation = 0
		
		get_parent().set_process_input(false)
		get_parent().radial_menu = true
		cam.set_process_input(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		show()
		
		
	if event.is_action_released("radial_menu"):
		radial_menu_off()
		
func radial_menu_off():
	$AnimationPlayer.play_backwards("zoom")
	$AnimationPlayer.seek(0)
	
	time_scale_target = 1
	Engine.time_scale = 1
	
	get_parent().set_process_input(true)
	get_parent().radial_menu = false
	cam.set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	
	if current_item != -1:
		get_parent().switch_weapon(current_item)
	
func _physics_process(delta):
	
	if interpolation <= 1:
		interpolation += delta
	
	Engine.time_scale = lerp(Engine.time_scale, time_scale_target, interpolation)





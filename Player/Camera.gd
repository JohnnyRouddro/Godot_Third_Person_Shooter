extends Spatial

var camrot_h = 0
var camrot_v = 0
var cam_v_max = 65
var cam_v_min = -45
var h_sensitivity = 0.1
var h_sensitivity_aim = 0.04
var v_sensitivity = 0.1
var v_sensitivity_aim = 0.04
var h_acceleration = 10
var v_acceleration = 10

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$h/v/pivot/Camera.add_exception(get_parent())
	
func _input(event):
	if event is InputEventMouseMotion:
		
		var aim_transition = get_node("../AnimationTree").get("parameters/aim_transition/current")
		
		camrot_h += -event.relative.x * (h_sensitivity * aim_transition + h_sensitivity_aim * (1-aim_transition))
		camrot_v += event.relative.y * (v_sensitivity * aim_transition + v_sensitivity_aim * (1-aim_transition))
		
func _physics_process(delta):
	
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)
	
	$h.rotation_degrees.y = lerp($h.rotation_degrees.y, camrot_h, delta * h_acceleration)
	$h/v.rotation_degrees.x = lerp($h/v.rotation_degrees.x, camrot_v, delta * v_acceleration)

func recoil_recovery():
	camrot_v -= get_node("../WeaponStats").recoil()/2

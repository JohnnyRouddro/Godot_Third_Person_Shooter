extends KinematicBody

onready var gun_attachment = $Mesh/Godot_Chan_Stealth_Shooter/Godot_Chan_Stealth/Skeleton/gun_attachment
onready var neck_attachment = $Mesh/Godot_Chan_Stealth_Shooter/Godot_Chan_Stealth/Skeleton/neck_attachment
onready var weapon_fire = [preload("res://Audio/Rifle_fire.wav"), preload("res://Audio/Pistol_fire.wav")]
onready var weapon_reload = [preload("res://Audio/Rifle_reload.wav"), preload("res://Audio/Pistol_reload.wav")]
onready var weapon_ray = $Camroot/h/v/pivot/Camera/ray

var weapons = ["Rifle", "Pistol"]
var current_weapon = -1
var fired_once = false

var direction = Vector3.BACK
var velocity = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0

var vertical_velocity = 0
var gravity = 28
var weight_on_ground = 5

var movement_speed = 0
var walk_speed = 2.2
var crouch_walk_speed = 1
var run_speed = 5
var acceleration = 6
var angular_acceleration = 7

var jump_magnitude = 15
var roll_magnitude = 20

var sprint_toggle = true
var sprinting = false

var ag_transition = "parameters/ag_transition/current"
var ag_weapon_transition = "parameters/ag_weapon_transition/current"
var aim_transition = "parameters/aim_transition/current"
var crouch_iw_blend = "parameters/crouch_iw_blend/blend_amount"
var crouch_walk_blendspace = "parameters/crouch_walk/blend_position"
var cs_transition = "parameters/cs_transition/current"
var ir_rifle_blend = "parameters/ir_rifle_blend/blend_amount"
var iwr_blend = "parameters/iwr_blend/blend_amount"
var jump_blend = "parameters/jump_blend/blend_position"
var reload_active = "parameters/reload/active"
var roll_active = "parameters/roll/active"
var roll_blend = "parameters/roll_blend/blend_position"
var walk_blendspace = "parameters/walk/blend_position"
var weapon_blend = "parameters/weapon_blend/blend_amount"
var weapon_switch_active = "parameters/weapon_switch/active"

var cam_holster = "parameters/holster/blend_amount"
var cam_shoulder = "parameters/shoulder_weapon/blend_position"
var cam_crouch_stand = "parameters/crouch_stand/blend_position"
var cam_aim = "parameters/aim/blend_position"

var weapon_blend_target = 1
var crouch_stand_target = 1
var shoulder_target = 0.5

var aim_speed = 10

var radial_menu = false

var splatter = 0
var weapon_ray_tip = Vector3()

func _ready():
	randomize()
	direction = Vector3.BACK.rotated(Vector3.UP, $Camroot/h.global_transform.basis.get_euler().y)
	# Sometimes in the level design you might need to rotate the Player object itself
	# So changing the direction at the beginning
	
	$AnimationTree.set("parameters/walk_scale/scale", walk_speed)
	switch_weapon(0)
	$splatters.set_as_toplevel(true)

func _input(event):
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015 # animates player strafe, when standing, aiming, and looking left right
	
	if event is InputEventKey:
		if event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Space" || event.as_text() == "Control" || event.as_text() == "Shift" || event.as_text() == "X" || event.as_text() == "F" || event.as_text() == "Q" || event.as_text() == "C" || event.as_text() == "Z" || event.as_text() == "R":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")

	if sprint_toggle:
		if event.is_action_pressed("sprint"):
			sprinting = !sprinting
	else:
		sprinting = Input.is_action_pressed("sprint")
			
	if Input.is_key_pressed(KEY_1):
		switch_weapon(0)
	if Input.is_key_pressed(KEY_2):
		switch_weapon(1)
		
	if event.is_action_pressed("holster"):
		weapon_blend_target = 1 - weapon_blend_target
		gun_attachment.set("visible", !gun_attachment.get("visible"))
	
	if event.is_action_pressed("crouch"):
		if $crouch_timer.is_stopped() && !$AnimationTree.get(roll_active):
			$crouch_timer.start()
			$AnimationTree.tree_root.get_node("cs_transition").xfade_time = (velocity.length() + 1.5)/ 15.0
			crouch_stand_target = 1 - crouch_stand_target
			$AnimationTree.set(cs_transition, crouch_stand_target)
		
	
	if weapon_blend_target:
		
		if event.is_action_pressed("shoulder_change"):
			shoulder_target *= -1.0
			
		if $AnimationTree.get(aim_transition) == 0:
			
			if event.is_action_pressed("lean_right"):
				shoulder_target = 0.5 if shoulder_target == 1.0 else 1.0
	
			if event.is_action_pressed("lean_left"):
				shoulder_target = -0.5 if shoulder_target == -1.0 else -1.0
				
		if event.is_action_pressed("reload"):
			reload()
	
	if event.is_action_released("fire"):
		fired_once = false
		
	if event.is_action_pressed("next_weapon"):
		switch_weapon(current_weapon + 1 if current_weapon < weapons.size() - 1 else 0)
	
	if event.is_action_pressed("prev_weapon"):
		switch_weapon(current_weapon - 1 if current_weapon > 0 else  weapons.size() - 1)
#
	

func _physics_process(delta):
	
	if !$roll_timer.is_stopped(): # we only need roll_timer to change acceleration in the middle (using wait_time)
		acceleration = 3.5
	else:
		acceleration = 5
	
	if Input.is_action_pressed("aim"):
		$Status/Aim.color = Color("ff6666")
	else:
		$Status/Aim.color = Color("ffffff")
	
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if !radial_menu:
	
		if Input.is_action_pressed("forward") ||  Input.is_action_pressed("backward") ||  Input.is_action_pressed("left") ||  Input.is_action_pressed("right"):
			
			direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
						0,
						Input.get_action_strength("forward") - Input.get_action_strength("backward"))
	
			strafe_dir = direction
			
			direction = direction.rotated(Vector3.UP, h_rot).normalized()
			
			if sprinting && $AnimationTree.get(aim_transition) == 1 && crouch_stand_target:
				movement_speed = run_speed
			else:
				if crouch_stand_target:
					movement_speed = walk_speed
				else:
					movement_speed = crouch_walk_speed
				
		else:
			movement_speed = 0
			strafe_dir = Vector3.ZERO
			
			if $AnimationTree.get(aim_transition) == 0:
				direction = $Camroot/h.global_transform.basis.z
	
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

	move_and_slide(velocity + Vector3.UP * vertical_velocity - get_floor_normal() * weight_on_ground, Vector3.UP)
	
	if !is_on_floor():
		vertical_velocity -= gravity * delta
	else:
		if vertical_velocity < -20:
			roll()
		vertical_velocity = 0
	
# ======================================= AIM MODE START ==============================

	if !radial_menu:
		
		if (Input.is_action_pressed("aim")) && !$AnimationTree.get(roll_active) && weapon_blend_target == 1:
			$CamAnimTree.set(cam_aim, lerp($CamAnimTree.get(cam_aim), 1, delta * aim_speed))
		else:
			$CamAnimTree.set(cam_aim, lerp($CamAnimTree.get(cam_aim), 0, delta * aim_speed))

		if (Input.is_action_pressed("aim") || Input.is_action_pressed("fire") || !$aim_stay_delay.is_stopped()) && !$AnimationTree.get(roll_active) && weapon_blend_target == 1:
			
			if Input.is_action_pressed("fire"):
				$aim_stay_delay.start()
				
				if $shoot_timer.is_stopped() && $reload_timer.is_stopped() && !$AnimationTree.get(weapon_switch_active) && $WeaponStats.mag() > 0 && ($WeaponStats.auto() || !fired_once):# weapon stats 

					fired_once = true
					
					$shoot_timer.start(1 / $WeaponStats.fire_rate())
					$shoot_sfx.play()
				
					$WeaponStats.mag_decrement()
				
					$UI/Crosshair.fire($WeaponStats.fire_rate() * 0.2)
				
					neck_attachment.get_node("AnimationPlayer").play("muzzle_flash")
				
					
					$splatters.get_child(splatter).global_transform.origin = weapon_ray_tip
					$splatters.get_child(splatter).emitting = true
					
					splatter += 1
					if splatter >= $splatters.get_child_count() - 1:
						splatter = 0
					
					var spread = $UI/Crosshair.pos_x/12
					weapon_ray.rotation_degrees.x = rand_range(-spread, spread)
					weapon_ray.rotation_degrees.y = rand_range(-spread, spread)
					
					$Camroot/h/v.rotate_x(deg2rad($WeaponStats.recoil()))
					$Camroot.recoil_recovery()
					
			
			if $AnimationTree.get(aim_transition) == 1:
				$AnimationTree.set(aim_transition, 0)
				$Mesh/Godot_Chan_Stealth_Shooter/Godot_Chan_Stealth/Skeleton/spine_ik.start()
				$AnimationTree.set("parameters/neck_front/blend_amount", 1)
			
			if $AnimationTree.get(roll_active):
				$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
				# Sometimes in the level design you might need to rotate the Player object itself
				# - rotation.y in case you need to rotate the Player object
			else:
				$Mesh.rotation.y = $Camroot/h.rotation.y # when not rolling, Mesh will face where camera is facing. Not lerping as weapon will lerp too.
			
			
			strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
			
			if !$AnimationTree.get(roll_active):
				$AnimationTree.set(walk_blendspace, Vector2(-strafe.x, strafe.z))
				$AnimationTree.set(crouch_walk_blendspace, Vector2(-strafe.x, strafe.z))
			
			$AnimationTree.set(iwr_blend, lerp($AnimationTree.get(iwr_blend), 0, delta * acceleration))
			$AnimationTree.set(crouch_iw_blend, lerp($AnimationTree.get(crouch_iw_blend), 1, delta * acceleration))
				
		else:
			shoulder_target = 0.5 * sign(shoulder_target)
		
			if $AnimationTree.get(aim_transition) == 0:
				$AnimationTree.set(aim_transition, 1)
				$Mesh/Godot_Chan_Stealth_Shooter/Godot_Chan_Stealth/Skeleton/spine_ik.stop()
				$Mesh/Godot_Chan_Stealth_Shooter/Godot_Chan_Stealth/Skeleton.clear_bones_global_pose_override()
				$AnimationTree.set("parameters/neck_front/blend_amount", 0)
				
			
			$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		
			if !$AnimationTree.get(roll_active): # so that roll anim fades out to last walk anim blend position
				$AnimationTree.set(walk_blendspace, lerp($AnimationTree.get(walk_blendspace), Vector2(0,1), delta * acceleration))
				$AnimationTree.set(crouch_walk_blendspace, lerp($AnimationTree.get(crouch_walk_blendspace), Vector2(0,1), delta * acceleration))
		
			var iw_blend = (velocity.length() - walk_speed) / walk_speed
			var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
		
			#find the graph here: https://www.desmos.com/calculator/4z9devx1ky
		
			if velocity.length() <= walk_speed:
				$AnimationTree.set(iwr_blend , iw_blend)
				$AnimationTree.set(ir_rifle_blend, 0)
			else:
				$AnimationTree.set(iwr_blend , wr_blend)
				$AnimationTree.set(ir_rifle_blend, wr_blend)
		
			$AnimationTree.set(crouch_iw_blend, velocity.length()/crouch_walk_speed)
		
	# ======================================= AIM MODE END ===================================
	
	
	
	# ======================================= JUMP/ ROLL START ===============================
	
		if is_on_floor():
	
			$AnimationTree.set(ag_transition, 1)
			$AnimationTree.set(ag_weapon_transition, crouch_stand_target)
	
			if !$AnimationTree.get(roll_active):
				if Input.is_action_just_pressed("jump"):
					crouch_stand_target = 1
					$AnimationTree.set(cs_transition, 1)
					
					vertical_velocity = jump_magnitude
	
				if Input.is_action_just_pressed("roll"):
					roll()
					
		else:
			$AnimationTree.set(ag_transition, 0)
			$AnimationTree.set(ag_weapon_transition, 0)
			
			$AnimationTree.set(jump_blend, lerp($AnimationTree.get(jump_blend), vertical_velocity/jump_magnitude, delta * 10))
			
	# ======================================= JUMP/ ROLL END ================================
	
		
		$AnimationTree.set(weapon_blend, lerp($AnimationTree.get(weapon_blend), weapon_blend_target, delta * 10))
		$AnimationTree.set(roll_blend, lerp($AnimationTree.get(roll_blend), weapon_blend_target, delta * 5))
		
		$CamAnimTree.set(cam_holster, lerp($CamAnimTree.get(cam_holster), weapon_blend_target, delta * 5))
		$CamAnimTree.set(cam_shoulder, lerp($CamAnimTree.get(cam_shoulder), shoulder_target, delta * 7))
		$CamAnimTree.set(cam_crouch_stand, lerp($CamAnimTree.get(cam_crouch_stand), crouch_stand_target, delta * 4))
	
	
		if $WeaponStats.mag() < 1 && $reload_timer.is_stopped() && !$AnimationTree.get(roll_active):
			reload()
		
		aim_turn = 0
		
		$UI/Crosshair.pos_x = $WeaponStats.spread() + $WeaponStats.movement_spread() * velocity.length() + $WeaponStats.jump_spread() * int(!is_on_floor())
		$UI/Crosshair.pos_x += $WeaponStats.aim_spread() * $CamAnimTree.get(cam_aim) + $WeaponStats.crouch_spread() * (1 - crouch_stand_target)
		
		$UI/Mag/mag.text = String($WeaponStats.mag())
		$UI/Mag/ammo_backup.text = String($WeaponStats.ammo_backup())
		
	
	if weapon_ray.is_colliding() && (weapon_ray.get_collision_point()-weapon_ray.global_transform.origin).length() > 0.1:
		weapon_ray_tip = weapon_ray.get_collision_point()
	else:
		weapon_ray_tip = (weapon_ray.get_cast_to().z * weapon_ray.global_transform.basis.z) + weapon_ray.global_transform.origin
	
	neck_attachment.get_node("streaks").look_at(weapon_ray_tip, Vector3.UP)
	
func roll():
	$AnimationTree.set(roll_active, true)
	$roll_timer.start()
	velocity = (direction - get_floor_normal()) * roll_magnitude
	$AnimationTree.set(reload_active, false) #cancelling reload if rolling
	$reload_timer.stop() #cancelling reload if rolling
	
	$AnimationTree.set(crouch_walk_blendspace, Vector2(0, 0))
	# so that roll anim fades out to crouch idle anim
	# need this only for crouch as blending roll to crouch_walk gives weirdness (for the difference of root bone position)


func switch_weapon(to):
	
	if to < weapons.size() && (to != current_weapon || weapon_blend_target == 0):
		weapon_blend_target = 1
		gun_attachment.show()
		
		$AnimationTree.set("parameters/weapon_change_aim/blend_position", to)
		$AnimationTree.set("parameters/weapon_change_on_air/blend_position", to)
		$AnimationTree.set("parameters/weapon_change_idle/blend_position", to)
		$AnimationTree.set("parameters/weapon_change_run/blend_position", to)
		$AnimationTree.set("parameters/weapon_change_switch/blend_position", to)
		
		
		gun_attachment.get_node(weapons[current_weapon]).hide()
		current_weapon = to
		gun_attachment.get_node(weapons[current_weapon]).show()

		$AnimationTree.set("parameters/weapon_switch_scale/scale", $WeaponStats.switch_speed())
		$AnimationTree.set("parameters/weapon_switch_seek/seek_position", 0)
		$AnimationTree.set(weapon_switch_active, true)
		
		$reload_timer.stop()#cancelling reload if weapon switching
		$AnimationTree.set(reload_active, false)#cancelling reload if weapon switching
		
		neck_attachment.get_node("muzzle_flash").speed_scale = $WeaponStats.fire_rate()
		neck_attachment.get_node("streaks").speed_scale = $WeaponStats.fire_rate() / 1.45
		neck_attachment.get_node("streaks").process_material.gravity.z = -(8000 / $WeaponStats.fire_rate())
		neck_attachment.get_node("AnimationPlayer").playback_speed = clamp($WeaponStats.fire_rate(), 5, 10)
		$shoot_sfx.stream.audio_stream = weapon_fire[current_weapon]


func reload():
	if $WeaponStats.mag() != $WeaponStats.mag_size() && $WeaponStats.ammo_backup() != 0:
		$AnimationTree.set("parameters/reload_scale/scale", $WeaponStats.reload_speed())
		$AnimationTree.set(reload_active, true)
		$reload_timer.start(1 / $WeaponStats.reload_speed())
		$reload_sfx.stream = weapon_reload[current_weapon]
		$reload_sfx.play()
		
func _on_reload_timer_timeout():
	$WeaponStats.mag_fill()
	




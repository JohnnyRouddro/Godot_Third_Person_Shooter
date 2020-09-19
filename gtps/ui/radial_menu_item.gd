extends Control

func _on_button_pressed():
	
	get_node("../../../").switch_weapon(name.to_int())
	get_node("../../").radial_menu_off()


func _on_button_mouse_entered():
	get_node("../../").current_item = name.to_int()

func _on_button_mouse_exited():
	get_node("../../").current_item = -1

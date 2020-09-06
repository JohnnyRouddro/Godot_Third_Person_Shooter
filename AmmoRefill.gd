extends Spatial

export(String, "Rifle", "Pistol") var ammo_type = "Rifle"

func _ready():
	$Viewport/Control/Label.text = ammo_type + "\nRefill"
	$MeshInstance.material_override = SpatialMaterial.new()
	$MeshInstance.material_override.set_cull_mode(SpatialMaterial.CULL_DISABLED)
	$MeshInstance.material_override.albedo_texture = $Viewport.get_texture()


func _on_Area_body_entered(body):
	if body.is_in_group("Player"):
		body.get_node("WeaponStats").ammo_refill(ammo_type)
		pass

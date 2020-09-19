extends Node

onready var player = get_parent()

var Rifle_stats = {"spread": 18.0, "movement_spread": 5.5, "aim_spread": -7,
					"crouch_spread": -6, "jump_spread": 12, "reload_speed": 0.8, "switch_speed": 1.2, "fire_rate": 8.0, "auto": true,
					"mag": 40, "mag_size": 40, "ammo_backup": 40, "ammo_backup_max": 40, "recoil": 0.8}

var Pistol_stats = {"spread": 25.0, "movement_spread": 3.5, "aim_spread": -7,
					"crouch_spread": -5, "jump_spread": 10, "reload_speed": 0.8, "switch_speed": 1.5, "fire_rate": 6.0, "auto": false,
					"mag":15, "mag_size": 15, "ammo_backup": 30, "ammo_backup_max": 30, "recoil": 0.5}

var weapon_stats = {"Rifle": Rifle_stats, "Pistol": Pistol_stats}


# setters

func mag_decrement():
	weapon_stats[weapon_name()]["mag"] -= 1

func mag_fill():
	var empty_space = mag_size() - mag()
	weapon_stats[weapon_name()]["mag"] += min(empty_space, ammo_backup())
	weapon_stats[weapon_name()]["ammo_backup"] -= min(empty_space, ammo_backup())

func ammo_refill(ammo_type):
	weapon_stats[ammo_type]["ammo_backup"] = weapon_stats[ammo_type]["ammo_backup_max"]
	weapon_stats[ammo_type]["mag"] = weapon_stats[ammo_type]["mag_size"]


# getters

func weapon_name():
	return player.weapons[player.current_weapon]

func spread():
	return weapon_stats[weapon_name()]["spread"]

func movement_spread():
	return weapon_stats[weapon_name()]["movement_spread"]

func aim_spread():
	return weapon_stats[weapon_name()]["aim_spread"]

func crouch_spread():
	return weapon_stats[weapon_name()]["crouch_spread"]

func jump_spread():
	return weapon_stats[weapon_name()]["jump_spread"]

func reload_speed():
	return weapon_stats[weapon_name()]["reload_speed"]

func fire_rate():
	return weapon_stats[weapon_name()]["fire_rate"]

func auto():
	return weapon_stats[weapon_name()]["auto"]

func recoil():
	return weapon_stats[weapon_name()]["recoil"]

func mag():
	return weapon_stats[weapon_name()]["mag"]

func mag_size():
	return weapon_stats[weapon_name()]["mag_size"]

func ammo_backup():
	return weapon_stats[weapon_name()]["ammo_backup"]

func switch_speed():
	return weapon_stats[weapon_name()]["switch_speed"]

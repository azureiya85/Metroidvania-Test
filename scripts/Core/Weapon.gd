extends Node2D

var attack_damage : int = 10
var knockback_force : int = 100

func _on_hitbox_area_entered(area):
	if area is HitBox:
		var hitbox : HitBox = area
		var attack = Attack.new()
		attack.attack_damage = attack_damage  # Assuming attack_damage is defined earlier in the script
		attack.knockback_force = knockback_force  # Assuming knockback_force is defined earlier in the script
		attack.attack_position = global_position
		hitbox.get_damage()

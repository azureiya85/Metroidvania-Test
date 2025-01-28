extends Node2D

var attack_damage = 10
var knockback_force = 100

func _on_hitbox_area_entered(area):
	if area is HitboxComp:
		var hitbox : HitboxComp = area
		var attack = Attack.new()
		attack.attack_damage = attack_damage  # Assuming attack_damage is defined earlier in the script
		attack.knockback_force = knockback_force  # Assuming knockback_force is defined earlier in the script
		attack.attack_position = global_position
		hitbox.damage(attack)

class_name HurtBox
extends Area2D

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(hitbox: HitBox) -> void:
	# Ignore collisions with own hitbox
	if hitbox.owner == self.owner:
		return

	if owner.has_method("take_damage"):
		var knockback_direction = (global_position - hitbox.global_position).normalized()
		
		# Handle cases where the damage method has different argument counts
		var damage = hitbox.get_damage()
		if owner.get_method_argument_count("take_damage") == 1:
			owner.take_damage(damage)
		else:
			owner.take_damage(damage, knockback_direction)

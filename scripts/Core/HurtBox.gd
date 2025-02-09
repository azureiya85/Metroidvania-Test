extends Area2D
class_name HurtBox

signal take_damage(damage: int, knockback_vector: Vector2)

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	# Ensure the area is a HitBox
	if not area is HitBox:
		return
	var hitbox : Area2D = area as HitBox

	if hitbox.owner == owner:
		return

	var health_component : Node2D = owner.get_node("HealthComp")
	if health_component:
		var damage: int = int(hitbox.attack.attack_damage)
		var knockback_force: float = hitbox.get_knockback_force(hitbox.attack)
		var knockback_direction: Vector2 = (global_position - hitbox.global_position).normalized()
		var knockback_vector: Vector2 = knockback_direction * knockback_force

		health_component.take_damage(damage)
		take_damage.emit(damage, knockback_vector)

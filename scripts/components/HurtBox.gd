class_name HurtBox
extends Area2D

signal take_damage(damage: int, knockback_vector: Vector2)

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox.owner == owner:
		return

	var health_component = owner.get_node("HealthComp")
	if health_component:
		var damage : int = hitbox.get_damage(hitbox.attack)
		var knockback_force : float  = hitbox.get_knockback_force(hitbox.attack)
		var knockback_direction : Vector2 = (global_position - hitbox.global_position).normalized()
		var knockback_vector : Vector2 = knockback_direction * knockback_force

		health_component.take_damage(damage)
		take_damage.emit(damage, knockback_vector)

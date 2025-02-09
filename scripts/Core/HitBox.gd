extends Area2D
class_name HitBox

@export var attack: Attack
@export var health_component: HealthComp

func get_knockback_force(attack: Attack) -> float:
	return attack.knockback_force

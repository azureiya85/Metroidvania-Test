extends Area2D
class_name HitboxComp

var health_comp: HealthComp

func damage(attack: Attack):
	if health_comp:
		health_comp.damage(attack)

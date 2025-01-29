extends Node2D
class_name HealthComp

@export var max_health := 10
var health: int

func _ready():
	health = max_health

#func damage(attack: Attack):
#	health -= attack.attack_damage
	
	if health <= 0:
		get_parent().queue_free()

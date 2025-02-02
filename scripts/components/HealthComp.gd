extends Node2D
class_name HealthComp

@export var max_health : int = 10
var health: int

func _ready() -> void: 
	health = max_health

func damage(attack: Attack) -> void:
	health -= attack.attack_damage
	
	if health <= 0:
		get_parent().queue_free()

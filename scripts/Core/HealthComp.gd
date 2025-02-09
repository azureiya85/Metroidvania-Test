extends Node2D
class_name HealthComp

@export var max_health: int = 10
var health: int
var current_health: int

signal health_updated(new_health : int)
signal died

func _ready() -> void:
	health = max_health

func is_dead() -> bool:
	return current_health <= 0

func take_damage(damage: int) -> void:
	health -= damage
	health_updated.emit(health)
	if health <= 0:
		died.emit()
		get_parent().queue_free()

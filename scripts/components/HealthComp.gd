extends Node2D
class_name HealthComp

@export var max_health : int = 10
var health: int

signal health_updated(new_health)
signal died

func _ready() -> void:
	health = max_health

func take_damage(damage: int) -> void:
	health = max(0, health - damage)
	health_updated.emit(health)
	if health <= 0:
		died.emit()
		get_parent().queue_free()

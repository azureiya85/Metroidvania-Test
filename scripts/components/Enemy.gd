extends CharacterBody2D


func take_damage(damage : int, knockback_direction : Vector2) -> void:
	print("take damage")
	health = max(0, health - damage)
	if health < 0:
		queue_free()
	pass
	
var health : int
var max_health : int = 10

func _ready() -> void:
	health = max_health

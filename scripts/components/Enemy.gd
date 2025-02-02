extends CharacterBody2D


func take_damage(damage, knockback_direction) -> void:
	print("take damage")
	health = max(0, health - damage)
	if health < 0:
		queue_free()
	pass
	
var health
var max_health = 10

func _ready():
	health = max_health

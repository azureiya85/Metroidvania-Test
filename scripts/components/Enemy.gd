extends CharacterBody2D

var taking_damage = false

func damage(attack: Attack):
	health -= attack.attack_damage
	
	if health <= 0:
		queue_free()
	
	taking_damage = true
	
	velocity =(global_position - attack.attack_position).normalized()*attack.knockdown_force
	
var health
var max_health = 10

func _ready():
	health = max_health

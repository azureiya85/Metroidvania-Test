class_name HitBox
extends Area2D

@export var damage := 10

func get_damage() -> int:
	print("damage")
	return damage 

# hack - early implementation of hitbox and hurtbox system, still needs a ton of work

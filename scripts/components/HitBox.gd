class_name HitBox
extends Area2D

@export var Attack: Resource

func get_damage(attack: Attack) -> int:
	return attack.attack_damage

func get_knockback_force(attack: Attack) -> float:
	return attack.knockback_force

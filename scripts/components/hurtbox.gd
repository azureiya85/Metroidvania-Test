class_name Hurtbox
extends Area2D

func _on_Hurtbox_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(1, Vector2.ZERO)

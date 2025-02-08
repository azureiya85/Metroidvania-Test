extends CharacterBody2D
class_name Enemy

@onready var hurtbox: HurtBox = $HurtBox

func _ready() -> void:
	hurtbox.take_damage.connect(_on_hurtbox_take_damage)

func _on_hurtbox_take_damage(damage: int, knockback_vector: Vector2) -> void:
	# Apply knockback effect; adjust velocity as needed.
	velocity = knockback_vector
	move_and_slide()

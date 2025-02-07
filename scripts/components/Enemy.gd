extends CharacterBody2D

@onready var hurtbox : HurtBox = $HurtBox
#@export var knockback_resistance: float = 1.0  # Adjust as needed

func _ready() -> void:
	hurtbox.take_damage.connect(_on_hurtbox_take_damage)

func _on_hurtbox_take_damage(damage: int, knockback_vector: Vector2):
	# Apply knockback effect
	velocity = knockback_vector #/ knockback_resistance
	move_and_slide()

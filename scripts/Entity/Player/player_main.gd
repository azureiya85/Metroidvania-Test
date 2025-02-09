extends CharacterBody2D

# Get references to our modular nodes.
@onready var movement: Node = $Movement
@onready var animation_controller: Node = $Animation
@onready var combat: Node = $Combat
@onready var health_comp: HealthComp = $HealthComp
@onready var hurt_box_component: HurtBox = $"HurtBox Component"

func _ready() -> void:
	# Connect the health component’s death signal.
	health_comp.died.connect(_on_death)
	# When the HurtBox detects a hit, let the Combat module handle it.
	hurt_box_component.take_damage.connect(combat._on_hurt_box_take_damage)

func _physics_process(delta: float) -> void:
	# Do not process further if dead.
	if health_comp.is_dead():
		return
	# Process input and movement first…
	movement.process_input(delta)
	combat.process_input(delta)
	movement.apply_physics(delta)
	# …then update the animation state.
	animation_controller.update_state(movement, combat, health_comp)

func _process(delta: float) -> void:
	# Update any timers (for instance, invincibility) and animations.
	combat.update_timers(delta)
	animation_controller.update(delta)

func _on_death() -> void:
	animation_controller.play_animation("death")
	# Defer reloading so that the death animation can play.
	get_tree().call_deferred("reload_current_scene")

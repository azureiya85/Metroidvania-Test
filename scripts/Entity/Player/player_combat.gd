extends Node

signal attack_started
signal attack_finished
signal hurt_started
signal hurt_finished

@export var KNOCKBACK_SPEED: float = 100.0
@export var INVINCIBILITY_DURATION: float = 1.0

var is_attacking: bool = false
var is_hurt: bool = false
var is_invincible: bool = false
var invincibility_timer: float = 0.0

func process_input(delta: float) -> void:
	var player = get_parent()
	var movement = player.get_node("Movement")
	# Do not allow attacks if already attacking/hurt or if the player is sitting.
	if is_attacking or is_hurt or movement.is_sitting:
		return
	if Input.is_action_just_pressed("attack"):
		start_attack()

func start_attack() -> void:
	var player = get_parent()
	player.velocity.x = 0  # Stop horizontal movement during attack.
	is_attacking = true
	emit_signal("attack_started")
	# The Animation module will trigger finish_attack() when the attack animation ends.

func finish_attack() -> void:
	is_attacking = false
	emit_signal("attack_finished")

func _on_hurt_box_take_damage(damage: int, knockback_vector: Vector2) -> void:
	if is_invincible:
		return
	trigger_hurt(knockback_vector)
	print("Player took ", damage, " damage.")

func trigger_hurt(knockback_vector: Vector2) -> void:
	if is_hurt:
		return  # Already processing hurt.
		is_hurt = true
		is_invincible = true
	var player = get_parent()
	player.velocity = knockback_vector.normalized() * KNOCKBACK_SPEED
	emit_signal("hurt_started")
	# Wait for hurt duration.
	await get_tree().create_timer(0.5).timeout
	player.velocity = Vector2.ZERO
	emit_signal("hurt_finished")
	# Continue invincibility for a bit longer.
	await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
	is_hurt = false
	is_invincible = false

func update_timers(delta: float) -> void:
	# (Timers are handled by awaiting Timer timeouts above.
	#  This function is left here for any future manual updates.)
	pass

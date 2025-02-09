extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_animation: String = ""

func _ready() -> void:
	animation_player.connect("animation_finished", Callable(self, "_on_animation_player_animation_finished"))


func update_state(movement, combat, health_comp) -> void:
	if combat.is_hurt:
		play_animation("hurt")
		return
	if health_comp.is_dead():
		play_animation("death")
		return
	if combat.is_attacking:
		play_animation("attack")
		return
	if movement.is_sitting:
		if not movement.sit_idle_transitioned:
			play_animation("sit")
			transition_to_sit_idle()
			return
		else:
			play_animation("sit-idle")
			return
	
	var player = get_parent()
	if player.is_on_floor():
		if abs(player.velocity.x) < 0.1:
			play_animation("idle")
		else:
			play_animation("run")
	else:
		play_animation("jump")

	# Ensure the sprite faces the correct direction.
	flip_sprite(movement.facing_direction)

func play_animation(animation: String) -> void:
	if current_animation != animation:
		current_animation = animation
		animation_player.play(animation)

func transition_to_sit_idle() -> void:
	# Wait 0.5 seconds before switching to sit-idle.
	await get_tree().create_timer(0.5).timeout
	var movement = get_parent().get_node("Movement")
	if movement.is_sitting:
		movement.sit_idle_transitioned = true
		play_animation("sit-idle")

func _on_animation_player_animation_finished(anim_name: String) -> void:
	var combat = get_parent().get_node("Combat")
	if anim_name == "attack":
		combat.finish_attack()
	# (Add further handling if other animations need callbacks.)

func update(delta: float) -> void:
	# Place any per-frame animation updates here (if needed).
	pass

func flip_sprite(direction: int) -> void:
	var sprite = get_parent().get_node("CaelaSprite")
	if sprite:
		sprite.flip_h = (direction < 0)

extends CharacterBody2D

# Constants for movement
const SPEED = 300.0
const JUMP_VELOCITY = -420.0

# Animation states
enum AnimationState { IDLE, RUN, JUMP, SIT, SIT_IDLE, ATTACK, HURT, DEATH }

# Node references
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# State variables
var is_attacking = false
var is_sitting = false
var is_hurt = false
var is_dead = false
var sit_idle_transitioned = false  # Prevent repeated transitions to sit-idle

# Main physics process
func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Stop all actions if dead

	handle_gravity(delta)
	handle_input()
	handle_animation()
	move_and_slide()

# Handle gravity
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# Handle input logic
func handle_input() -> void:
	if is_dead or is_hurt or is_attacking:
		return  # Skip input processing during these states

	# Attack input has priority
	if Input.is_action_just_pressed("attack") and not is_sitting:
		is_attacking = true
		play_animation("attack-anim")
		return

	# Movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction and not is_sitting:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sitting:
		velocity.y = JUMP_VELOCITY

	# Crouch
	if Input.is_action_pressed("crouch") and is_on_floor():
		is_sitting = true
	else:
		is_sitting = false
		sit_idle_transitioned = false  # Reset sit-idle flag

	# Flip sprite based on direction
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true

# Handle animation transitions
func handle_animation() -> void:
	if is_hurt:
		play_animation("hurt")
		return
	if is_dead:
		play_animation("death")
		return
	if is_attacking:
		play_animation("attack-anim")
		return
	if is_sitting:
		if not sit_idle_transitioned:
			play_animation("sit")  # Play sit first
			transition_to_sit_idle()  # Schedule transition
		else:
			play_animation("sit-idle")  # Stay in sit-idle once transitioned
		return

	if is_on_floor():
		if velocity.x == 0:
			play_animation("idle")
		else:
			play_animation("run")
	else:
		play_animation("jump")

# Play animations
func play_animation(animation_name: String) -> void:
	if animated_sprite_2d.animation != animation_name:
		animated_sprite_2d.play(animation_name)

# Transition to sit-idle after sit animation
func transition_to_sit_idle() -> void:
	await get_tree().create_timer(0.5).timeout  # Adjust for sit animation length
	if is_sitting:
		sit_idle_transitioned = true  # Prevent repeated transitions
		play_animation("sit-idle")

# Reset state when animations finish
func _on_animated_sprite_2d_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"attack-anim":
			is_attacking = false
		"hurt":
			is_hurt = false

# Trigger hurt state
func trigger_hurt() -> void:
	is_hurt = true
	play_animation("hurt")

# Trigger death state
func trigger_death() -> void:
	is_dead = true
	velocity = Vector2.ZERO  # Stop movement
	play_animation("death")

# Handles player health and death

var max_health = 5
var current_health = max_health
var is_invincible = false
var invincibility_duration = 1.0
var invincibility_timer = 0.0

func _process(delta):
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= invincibility_duration:
			is_invincible = false
			invincibility_timer = 0.0

func take_damage(damage, knockback_direction):
	if !is_invincible:
		current_health -= damage
		if current_health <= 0:
			is_dead = true
		else:
			knockback(knockback_direction)

func heal(amount):
	current_health = min(max_health, current_health + amount)

func set_invincible(duration):
	is_invincible = true
	invincibility_duration = duration

func knockback(direction):
	var knockback_speed = 200
	var knockback_time = 0.5
	var velocity = direction.normalized() * knockback_speed
	play_animation("hurt")
	$CollisionShape2D.disabled = true
	$Timer.wait_time = knockback_time
	$Timer.start()
	# Apply knockback velocity to the player or enemy
	if has_node("CharacterBody2D"):
		var character_body = get_node("CharacterBody2D")
		character_body.kinematic_move(velocity)

func _on_Timer_timeout():
	play_animation("idle")
	$CollisionShape2D.disabled = false

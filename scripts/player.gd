extends CharacterBody2D

# Constants for movement
const SPEED = 300.0
const JUMP_VELOCITY = -420.0

# Animation states
enum AnimationState { IDLE, RUN, JUMP, SIT, SIT_IDLE, ATTACK, HURT, DEATH }

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# @onready var knockback_timer: Timer = $Timer

# State variables
var is_attacking = false
var is_sitting = false
var is_hurt = false
var is_dead = false
var sit_idle_transitioned = false
var is_invincible = false
var invincibility_timer = 0.0

# Player health
var max_health = 5
var current_health = max_health
var invincibility_duration = 1.0

# Main physics process
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	handle_gravity(delta)
	handle_input()
	handle_animation()
	move_and_slide()

# Handle gravity
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_input() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	if Input.is_action_just_pressed("attack") and not is_sitting:
		is_attacking = true
		play_animation("attack")
		return

	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0 and not is_sitting:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sitting:
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("crouch") and is_on_floor():
		is_sitting = true
	else:
		is_sitting = false
		sit_idle_transitioned = false

	if direction > 0:
		$CaelaSprite.flip_h = false
	elif direction < 0:
		$CaelaSprite.flip_h = true

func handle_animation() -> void:
	if is_hurt:
		play_animation("hurt")
		return
	if is_dead:
		play_animation("death")
		return
	if is_attacking:
		play_animation("attack")
		return
	if is_sitting:
		if not sit_idle_transitioned:
			play_animation("sit")
			transition_to_sit_idle()
		else:
			play_animation("sit-idle")
		return
	if is_on_floor():
		if velocity.x == 0:
			play_animation("idle")
		else:
			play_animation("run")
	else:
		play_animation("jump")

func play_animation(animation) -> void:
	if animation_player.current_animation != (animation):
		animation_player.play(animation)

func transition_to_sit_idle() -> void:
	await get_tree().create_timer(0.5).timeout
	if is_sitting:
		sit_idle_transitioned = true
		play_animation("sit-idle")

func _on_animation_player_animation_finished() -> void:
	match animation_player.current_animation:
		"attack":
			is_attacking = false
		"hurt":
			is_hurt = false

func trigger_hurt() -> void:
	if not is_invincible:
		is_hurt = true
		play_animation("hurt")
		set_invincible(invincibility_duration)

func trigger_death() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	play_animation("death")

func _process(delta):
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= invincibility_duration:
			is_invincible = false
			invincibility_timer = 0.0

func take_damage(damage, knockback_direction):
	if not is_invincible:
		current_health -= damage
		if current_health <= 0:
			trigger_death()
		else:
			knockback(knockback_direction)

func heal(amount):
	current_health = min(max_health, current_health + amount)

func set_invincible(duration):
	is_invincible = true
	invincibility_duration = duration

func knockback(direction: Vector2):
	var knockback_speed = 200.0
	velocity = direction.normalized() * knockback_speed
	play_animation("hurt")
	collision_shape.disabled = true
	# knockback_timer.start(0.5)

func _on_Timer_timeout():
	collision_shape.disabled = false
	play_animation("idle")

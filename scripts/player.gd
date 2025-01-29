extends CharacterBody2D

# Constants
const SPEED = 300.0  # Movement speed of the character
const JUMP_VELOCITY = -420.0  # Velocity applied when the character jumps
const KNOCKBACK_SPEED = 200.0  # Speed of the knockback effect when hurt
const INVINCIBILITY_DURATION = 1.0  # Duration of invincibility after taking damage

# Animation states
# Enum used to define various animation states for the character
enum AnimationState { IDLE, RUN, JUMP, SIT, SIT_IDLE, ATTACK, HURT, DEATH }

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Controls animations
@onready var collision_shape: CollisionShape2D = $CollisionShape2D  # Collision shape for the character
@onready var slash_area = $CaelaSprite/Area2D/SlashArea  # Slash attack detection area

# State variables
var is_attacking = false  # Indicates if the character is currently attacking
var is_sitting = false  # Indicates if the character is sitting
var is_hurt = false  # Indicates if the character is hurt
var is_dead = false  # Indicates if the character is dead
var sit_idle_transitioned = false  # Tracks whether the sit-idle animation has started
var is_invincible = false  # Indicates if the character is invincible after taking damage
var invincibility_timer = 0.0  # Timer for tracking invincibility duration

# Health
var max_health = 5  # Maximum health of the character
var current_health = max_health  # Current health of the character

# Handles physics updates for the character
func _physics_process(delta: float) -> void:
	if is_dead:  # Skip processing if the character is dead
		return

	handle_gravity(delta)  # Apply gravity
	handle_input()  # Handle player input
	handle_animation()  # Update animations based on state
	move_and_slide()  # Move the character

# Handles non-physics updates
func _process(delta: float) -> void:
	update_invincibility_timer(delta)  # Update the invincibility timer

# --- Movement Handling ---
# Applies gravity to the character if not on the floor
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# Processes player input for movement, attack, and jumping
func handle_input() -> void:
	if is_dead or is_hurt or is_attacking:  # Ignore input during these states
		return

	if Input.is_action_just_pressed("attack") and not is_sitting:
		start_attack()  # Start attack if "attack" action is triggered
		return

	handle_movement()  # Handle left/right movement
	handle_jump()  # Handle jumping
	handle_crouch()  # Handle crouching
	handle_flip_sprite()  # Flip sprite based on movement direction

# Handles character movement
func handle_movement() -> void:
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0 and not is_sitting:
		velocity.x = direction * SPEED  # Set horizontal velocity
		update_slash_area_direction(direction)  # Update slash attack direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)  # Gradually stop movement

# Handles jumping when "jump" action is triggered
func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sitting:
		velocity.y = JUMP_VELOCITY

# Handles crouching behavior
func handle_crouch() -> void:
	is_sitting = Input.is_action_pressed("crouch") and is_on_floor()
	if not is_sitting:
		sit_idle_transitioned = false

# Flips the sprite based on movement direction
func handle_flip_sprite() -> void:
	var direction = sign(velocity.x)
	if direction != 0:
		$CaelaSprite.flip_h = direction < 0

# --- Animation Handling ---
# Manages which animation to play based on the character state
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
		handle_sitting_animation()
		return
	if is_on_floor():
		play_animation("idle" if velocity.x == 0 else "run")
	else:
		play_animation("jump")

# Manages sitting animations, including transition to sit-idle
func handle_sitting_animation() -> void:
	if not sit_idle_transitioned:
		play_animation("sit")
		transition_to_sit_idle()  # Transition to sit-idle after a delay
	else:
		play_animation("sit-idle")

# Plays a specific animation if not already playing it
func play_animation(animation: String) -> void:
	if animation_player.current_animation != animation:
		animation_player.play(animation)

# Transitions from "sit" to "sit-idle" animation after a delay
func transition_to_sit_idle() -> void:
	await get_tree().create_timer(0.5).timeout
	if is_sitting:
		sit_idle_transitioned = true
		play_animation("sit-idle")

# --- Combat Handling ---
# Starts the attack sequence
func start_attack() -> void:
	velocity.x = 0  # Stop horizontal movement during attack
	is_attacking = true
	play_animation("attack")

# Triggers the hurt animation and state
func trigger_hurt() -> void:
	if not is_invincible:
		is_hurt = true
		play_animation("hurt")
		set_invincible(INVINCIBILITY_DURATION)

# Triggers the death state and animation
func trigger_death() -> void:
	is_dead = true
	velocity = Vector2.ZERO  # Stop movement
	play_animation("death")

# Handles taking damage and applying knockback
func take_damage(damage: int, knockback_direction: Vector2) -> void:
	if not is_invincible:
		current_health -= damage
		if current_health <= 0:
			trigger_death()
		else:
			knockback(knockback_direction)

# Heals the character by a specified amount
func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

# Sets the character as invincible for a duration
func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_timer = 0.0

# Updates the invincibility timer and disables invincibility if time is up
func update_invincibility_timer(delta: float) -> void:
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= INVINCIBILITY_DURATION:
			is_invincible = false
			invincibility_timer = 0.0

# Applies knockback effect and plays hurt animation
func knockback(direction: Vector2) -> void:
	velocity = direction.normalized() * KNOCKBACK_SPEED
	play_animation("hurt")
	collision_shape.disabled = true  # Temporarily disable collision
	await get_tree().create_timer(0.5).timeout
	collision_shape.disabled = false
	play_animation("idle")

# Updates the direction of the slash attack area
func update_slash_area_direction(direction: float) -> void:
	slash_area.position.x = abs(slash_area.position.x) * sign(direction)

# --- Animation Player Signals ---
# Resets states when animations complete
func _on_animation_player_animation_finished(anim_name: String) -> void:
	match anim_name:
		"attack":
			is_attacking = false
		"hurt":
			is_hurt = false

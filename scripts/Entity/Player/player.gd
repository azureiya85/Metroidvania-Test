extends CharacterBody2D

# Constants
const SPEED : float = 300.0  # Movement speed of the character
const JUMP_VELOCITY : float = -420.0  # Velocity applied when the character jumps
const KNOCKBACK_SPEED : float = 100.0  # Speed of the knockback effect when hurt
const INVINCIBILITY_DURATION : float = 1.0  # Duration of invincibility after taking damage

# Animation states
# Enum used to define various animation states for the character
enum AnimationState { IDLE, RUN, JUMP, SIT, SIT_IDLE, ATTACK, HURT, DEATH }

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Controls animations
@onready var collision_shape: CollisionShape2D = $Collision  # Collision shape for the character
@onready var slash_area : CollisionShape2D = $CaelaSprite/PlayerHitDetect/SlashArea  # Slash attack detection area
@onready var hurt_box_component: HurtBox = $"HurtBox Component"
@onready var health_comp: HealthComp = $HealthComp



# State variables
var is_attacking : bool = false  # Indicates if the character is currently attacking
var is_sitting : bool = false  # Indicates if the character is sitting
var is_hurt : bool= false  # Indicates if the character is hurt
var is_dead : bool = false  # Indicates if the character is dead
var sit_idle_transitioned : bool = false  # Tracks whether the sit-idle animation has started
var is_invincible : bool = false  # Indicates if the character is invincible after taking damage
var invincibility_timer : float = 0.0  # Timer for tracking invincibility duration
var facing_direction : int = 1 # Tracks the last facing direction, 1 for right, -1 for left

# --- Initialization ---
func _ready() -> void:
	# Connect the HurtBox signal so that when a hit occurs, we handle it here.
	hurt_box_component.take_damage.connect(_on_hurt_box_take_damage)
	# Optionally, connect HealthComp's death signal to trigger death.
	health_comp.died.connect(trigger_death)

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
	var direction : float = Input.get_axis("move_left", "move_right")
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
	if velocity.x != 0:
		facing_direction = sign(velocity.x)
	$CaelaSprite.flip_h = facing_direction < 0


# --- Animation Handling ---
# Manages which animation to play based on the character state
# todo - add sound effects
# todo - connect the hurt and death to an animation, but needs hitbox 
# and hurtbox figured out
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

# Maintain sprite flipping during non-movement states
	handle_flip_sprite()

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

# This function starts the attack sequence.
func start_attack() -> void:
	velocity.x = 0   # Stop horizontal movement during attack.
	is_attacking = true
	play_animation("attack")
	# (Optionally, enable your player's attack hitbox here.)
	
# This function is called by the HurtBox when the player is hit.
func _on_hurt_box_take_damage(damage: int, knockback_vector: Vector2) -> void:
	# If the player is invincible, ignore the hit.
	if is_invincible:
		return
	# (The HealthComp already subtracted damage.)
	# Now trigger the knockback and hurt animation.
	trigger_hurt(knockback_vector)
	print("Player took ", damage, " damage.")

# This function handles the death state.
func trigger_death() -> void:
	is_dead = true
	velocity = Vector2.ZERO     # Stop movement.
	play_animation("death")
	# Use call_deferred() so that scene reloading happens outside the physics callback.
	get_tree().call_deferred("reload_current_scene")

# This function triggers knockback and the hurt animation.
func trigger_hurt(knockback_direction: Vector2) -> void:
	if is_hurt:
		return  # Prevent re-triggering if already hurt.
		
	is_hurt = true
	is_invincible = true
	# Apply knockback by setting the velocity.
	velocity = knockback_direction.normalized() * KNOCKBACK_SPEED
	play_animation("hurt")
	
	# Store a reference to the SceneTree.
	var tree : SceneTree = get_tree()
	# Wait for the knockback/hurt duration.
	if tree:
		await tree.create_timer(0.5).timeout
	
	# If the node has been removed (e.g. scene reloaded), abort further processing.
	if not is_inside_tree():
		return
	
	# Wait for the knockback/hurt animation to finish (0.5 seconds here).
	await get_tree().create_timer(0.5).timeout
	velocity = Vector2.ZERO
	play_animation("idle")
	
	# Wait for the invincibility duration.
	if tree:
		await tree.create_timer(INVINCIBILITY_DURATION).timeout
	
	# Again, if the node is no longer in the scene tree, abort.
	if not is_inside_tree():
		return
	
	# End the hurt state.
	is_hurt = false
	is_invincible = false

# Heals the character by a specified amount

# Updates the invincibility timer and disables invincibility if time is up
func update_invincibility_timer(delta: float) -> void:
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= INVINCIBILITY_DURATION:
			is_invincible = false
			invincibility_timer = 0.0

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

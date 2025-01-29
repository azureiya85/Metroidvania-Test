extends CharacterBody2D

# Constants
const SPEED = 300.0
const JUMP_VELOCITY = -420.0
const KNOCKBACK_SPEED = 200.0
const INVINCIBILITY_DURATION = 1.0

# Animation states
enum AnimationState { IDLE, RUN, JUMP, SIT, SIT_IDLE, ATTACK, HURT, DEATH }

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var slash_area = $CaelaSprite/Area2D/SlashArea

# State variables
var is_attacking = false
var is_sitting = false
var is_hurt = false
var is_dead = false
var sit_idle_transitioned = false
var is_invincible = false
var invincibility_timer = 0.0

# Health
var max_health = 5
var current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	handle_gravity(delta)
	handle_input()
	handle_animation()
	move_and_slide()

func _process(delta: float) -> void:
	update_invincibility_timer(delta)

# --- Movement Handling ---
func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_input() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	if Input.is_action_just_pressed("attack") and not is_sitting:
		start_attack()
		return

	handle_movement()
	handle_jump()
	handle_crouch()
	handle_flip_sprite()

func handle_movement() -> void:
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0 and not is_sitting:
		velocity.x = direction * SPEED
		update_slash_area_direction(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sitting:
		velocity.y = JUMP_VELOCITY

func handle_crouch() -> void:
	is_sitting = Input.is_action_pressed("crouch") and is_on_floor()
	if not is_sitting:
		sit_idle_transitioned = false

func handle_flip_sprite() -> void:
	var direction = sign(velocity.x)
	if direction != 0:
		$CaelaSprite.flip_h = direction < 0

# --- Animation Handling ---
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

func handle_sitting_animation() -> void:
	if not sit_idle_transitioned:
		play_animation("sit")
		transition_to_sit_idle()
	else:
		play_animation("sit-idle")

func play_animation(animation: String) -> void:
	if animation_player.current_animation != animation:
		animation_player.play(animation)

func transition_to_sit_idle() -> void:
	await get_tree().create_timer(0.5).timeout
	if is_sitting:
		sit_idle_transitioned = true
		play_animation("sit-idle")

# --- Combat Handling ---
func start_attack() -> void:
	velocity.x = 0
	is_attacking = true
	play_animation("attack")

func trigger_hurt() -> void:
	if not is_invincible:
		is_hurt = true
		play_animation("hurt")
		set_invincible(INVINCIBILITY_DURATION)

func trigger_death() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	play_animation("death")

func take_damage(damage: int, knockback_direction: Vector2) -> void:
	if not is_invincible:
		current_health -= damage
		if current_health <= 0:
			trigger_death()
		else:
			knockback(knockback_direction)

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_timer = 0.0
#	invincibility_duration = duration

func update_invincibility_timer(delta: float) -> void:
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= INVINCIBILITY_DURATION:
			is_invincible = false
			invincibility_timer = 0.0

func knockback(direction: Vector2) -> void:
	velocity = direction.normalized() * KNOCKBACK_SPEED
	play_animation("hurt")
	collision_shape.disabled = true
	await get_tree().create_timer(0.5).timeout
	collision_shape.disabled = false
	play_animation("idle")

func update_slash_area_direction(direction: float) -> void:
	slash_area.position.x = abs(slash_area.position.x) * sign(direction)

# --- Animation Player Signals ---
func _on_animation_player_animation_finished(anim_name: String) -> void:
	match anim_name:
		"attack":
			is_attacking = false
		"hurt":
			is_hurt = false

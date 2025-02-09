extends Node

# You can adjust these values in the Inspector.
@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -420.0
@export var GRAVITY: float = 980.0

# These state variables are used by the Animation module.
var is_sitting: bool = false
var sit_idle_transitioned: bool = false
var facing_direction: int = 1  # 1 for right, -1 for left

func process_input(delta: float) -> void:
	var player = get_parent()  # The parent is the Player (CharacterBody2D)
	if not player:
		return

	# Crouch state.
	is_sitting = Input.is_action_pressed("crouch") and player.is_on_floor()
	if not is_sitting:
		sit_idle_transitioned = false

	# Horizontal movement.
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0 and not is_sitting:
		player.velocity.x = direction * SPEED
		facing_direction = int(sign(direction))
	else:
		# Gradually slow down when no movement input.
		player.velocity.x = move_toward(player.velocity.x, 0, SPEED * delta)

	# Jumping.
	if Input.is_action_just_pressed("jump") and player.is_on_floor() and not is_sitting:
		player.velocity.y = JUMP_VELOCITY

func apply_physics(delta: float) -> void:
	var player = get_parent()
	if not player:
		return
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
	# Use move_and_slide() from CharacterBody2D.
	player.velocity = player.move_and_slide(player.velocity, Vector2.UP)

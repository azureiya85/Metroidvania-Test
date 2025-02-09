extends CharacterBody2D
class_name Enemy

@onready var hurtbox: HurtBox = $HurtBox
@onready var health_comp: HealthComp = $HealthComp
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum EnemyState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: EnemyState = EnemyState.IDLE

func _ready() -> void:
	hurtbox.take_damage.connect(_on_hurtbox_take_damage)
	health_comp.died.connect(_on_death)
	# Initialize AI here (e.g. set a patrol path or start idle behavior)

func _physics_process(delta: float) -> void:
	match current_state:
		EnemyState.IDLE:
			_process_idle(delta)
		EnemyState.PATROL:
			_process_patrol(delta)
		EnemyState.CHASE:
			_process_chase(delta)
		EnemyState.ATTACK:
			_process_attack(delta)
		EnemyState.HURT:
			_process_hurt(delta)
		EnemyState.DEAD:
			# Optionally, do nothing in DEAD state.
			pass
	move_and_slide()

func _process_idle(delta: float) -> void:
	# Idle behavior (e.g., play idle animation, look around, then switch state).
	pass

func _process_patrol(delta: float) -> void:
	# Simple patrol logic.
	# For example, move left/right, then reverse direction on reaching a boundary.
	pass

func _process_chase(delta: float) -> void:
	# Logic for chasing the player.
	pass

func _process_attack(delta: float) -> void:
	# Attack logic (possibly playing an attack animation and enabling hitboxes).
	pass

func _process_hurt(delta: float) -> void:
	# While in hurt state, you might want to gradually reduce knockback or simply wait.
	pass

func _on_hurtbox_take_damage(_damage: int, knockback_vector: Vector2) -> void:
	_trigger_hurt(knockback_vector)
	print("Enemy hit, received damage: ", _damage)

func _trigger_hurt(knockback_vector: Vector2) -> void:
	current_state = EnemyState.HURT
	velocity = knockback_vector
	animation_player.play("hurt")
	
	# Use an asynchronous wait before recovering.
	var tree: SceneTree = get_tree()
	await tree.create_timer(0.5).timeout
	
	
	# Check that the enemy is still in the scene before continuing.
	if not is_inside_tree():
		return
		
	# Transition to a suitable state after hurt (e.g., resume patrol).
	current_state = EnemyState.PATROL

func _on_death() -> void:
	current_state = EnemyState.DEAD
	velocity = Vector2.ZERO
	animation_player.play("death")

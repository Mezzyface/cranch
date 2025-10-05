extends Node
class_name WanderMovementController

# Movement parameters
@export var wander_speed: float = 50.0
@export var min_walk_time: float = 2.0
@export var max_walk_time: float = 4.0
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 3.0
@export var gravity: float = 980.0
@export var platform_bounds: Vector2 = Vector2(400, 1520)  # Min and max X for platform

# State
var direction: int = 1  # 1 = right, -1 = left
var state: String = "idle"
var state_timer: float = 0.0
var current_state_duration: float = 0.0
var just_turned_around: bool = false  # Prevent rapid direction changes

# References (set by parent)
var character_body: CharacterBody2D
var animated_sprite: AnimatedSprite2D

func _ready():
	# Get references from parent
	character_body = get_parent() as CharacterBody2D
	if character_body:
		animated_sprite = character_body.get_node_or_null("AnimatedSprite2D")

	# Random starting direction
	if randf() > 0.5:
		direction = -1

	print("Starting direction: ", direction)

	# Apply initial sprite direction
	_update_sprite_direction()

	# Start with idle
	_start_idle()

func process_movement(delta: float):
	if not character_body:
		return

	state_timer += delta

	# Apply gravity for platformer
	if not character_body.is_on_floor():
		character_body.velocity.y += gravity * delta
	else:
		character_body.velocity.y = 0

	# Handle current state
	match state:
		"idle":
			_handle_idle(delta)
		"walking":
			_handle_walking(delta)

	# Check if should switch states
	if state_timer >= current_state_duration:
		_switch_state()

	# Apply movement
	character_body.move_and_slide()

	# Check platform bounds (with buffer to prevent vibration)
	var at_left_edge = character_body.position.x <= platform_bounds.x + 5
	var at_right_edge = character_body.position.x >= platform_bounds.y - 5

	if (at_left_edge or at_right_edge) and not just_turned_around:
		_turn_around()
		just_turned_around = true
	elif not at_left_edge and not at_right_edge:
		# Reset the flag when we're away from edges
		just_turned_around = false

func _handle_idle(_delta: float):
	character_body.velocity.x = 0
	_play_animation("idle")

func _handle_walking(_delta: float):
	character_body.velocity.x = direction * wander_speed
	_update_sprite_direction()
	_play_animation("walk")

	# Platform edge detection disabled - using platform_bounds instead
	# if character_body.is_on_floor():
	# 	_check_platform_edge()

func _play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

func _update_sprite_direction():
	if not animated_sprite:
		return

	# Flip sprite based on direction
	# Adjust these if sprite faces wrong way
	if direction > 0:
		animated_sprite.flip_h = true  # Right
	else:
		animated_sprite.flip_h = false  # Left

func _switch_state():
	match state:
		"idle":
			_start_walking()
		"walking":
			_start_idle()

func _start_idle():
	state = "idle"
	state_timer = 0.0
	current_state_duration = randf_range(min_idle_time, max_idle_time)

func _start_walking():
	state = "walking"
	state_timer = 0.0
	current_state_duration = randf_range(min_walk_time, max_walk_time)

	# Pick a random direction each time we start walking
	if randf() > 0.5:
		direction = 1
	else:
		direction = -1

	print("Started walking in direction: ", direction)

func _check_platform_edge():
	if not character_body:
		return

	# Raycast downward slightly ahead of the character to detect platform edge
	var raycast_offset = 20.0  # How far ahead to check
	var check_position = character_body.global_position + Vector2(direction * raycast_offset, 0)

	# Cast a ray downward from the check position
	var space_state = character_body.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		check_position,
		check_position + Vector2(0, 50)  # Check 50 pixels down
	)
	query.exclude = [character_body]
	query.collision_mask = 1  # Adjust if your platforms use different collision layer

	var result = space_state.intersect_ray(query)

	# If no floor detected ahead, turn around
	if result.is_empty():
		print("Platform edge detected! Turning around")
		_turn_around()

func _turn_around():
	direction *= -1
	print("Turning around! New direction: ", direction)

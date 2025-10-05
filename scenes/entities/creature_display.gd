extends CharacterBody2D
class_name CreatureDisplay

@export var wander_speed: float = 50.0
@export var min_walk_time: float = 2.0
@export var max_walk_time: float = 4.0
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 3.0
@export var min_emote_interval: float = 5.0
@export var max_emote_interval: float = 15.0
@export var emote_duration: float = 2.5
@export var hitbox_scale: float = 0.7  # Scale hitbox to 70% of sprite size

var creature_data: CreatureData
var wander_target: Vector2
var container_bounds: Rect2
var state_timer: float = 0.0
var current_state_duration: float = 0.0
var current_state: GlobalEnums.CreatureState = GlobalEnums.CreatureState.IDLE
var facing_direction: GlobalEnums.FacingDirection = GlobalEnums.FacingDirection.WALK_DOWN
var emote_timer: float = 0.0
var next_emote_time: float = 0.0
var current_emote_bubble = null

const EMOTE_BUBBLE = preload("res://scenes/windows/emote_bubble.tscn")

func _ready():
	_start_idle_state()
	next_emote_time = randf_range(min_emote_interval, max_emote_interval)

func set_creature_data(data: CreatureData):
	creature_data = data
	_update_sprite()
	_update_hitbox()
	# Note: Drag handling is now managed at container level


func _update_sprite():
	if not creature_data:
		return

	# Get sprite frames from GlobalEnums
	var sprite_frames = GlobalEnums.get_sprite_frames_for_species(creature_data.species)
	if sprite_frames and $AnimatedSprite2D:
		$AnimatedSprite2D.sprite_frames = sprite_frames

func _update_hitbox():
	if not creature_data or not $AnimatedSprite2D or not $CollisionShape2D:
		return

	# Wait for sprite frames to be loaded
	await get_tree().process_frame

	var sprite_frames = $AnimatedSprite2D.sprite_frames
	if not sprite_frames:
		return

	# Get the first frame from idle animation
	var current_texture = sprite_frames.get_frame_texture("idle", 0)

	if current_texture:
		var sprite_size = current_texture.get_size()

		# Create or update the rectangle shape
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = sprite_size * hitbox_scale

		$CollisionShape2D.shape = rect_shape

		# Position collision shape so bottom aligns with sprite bottom
		# Sprite is centered by default, so offset down by half the hitbox height
		var offset_y = (sprite_size.y - rect_shape.size.y) / 2.0
		$CollisionShape2D.position = Vector2(0, offset_y)

		print("Updated hitbox for %s: %v at offset %v (sprite: %v)" % [creature_data.creature_name, rect_shape.size, $CollisionShape2D.position, sprite_size])

func set_container_bounds(bounds: Rect2):
	# Store the container bounds with padding
	var padding = 20.0
	container_bounds = Rect2(
		bounds.position.x + padding,
		bounds.position.y + padding,
		bounds.size.x - padding * 2,
		bounds.size.y - padding * 2
	)
	# Ensure initial position is within bounds
	position = _clamp_to_bounds(position)
	_pick_new_wander_target()

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, container_bounds.position.x, container_bounds.position.x + container_bounds.size.x),
		clamp(pos.y, container_bounds.position.y, container_bounds.position.y + container_bounds.size.y)
	)

func _get_walking_direction(direction_vector: Vector2) -> GlobalEnums.FacingDirection:
	# Determine primary direction based on vector
	var angle = direction_vector.angle()

	# Convert angle to degrees and normalize to 0-360
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	# Determine direction based on angle quadrants
	if degrees >= 315 or degrees < 45:
		return GlobalEnums.FacingDirection.WALK_RIGHT
	elif degrees >= 45 and degrees < 135:
		return GlobalEnums.FacingDirection.WALK_DOWN
	elif degrees >= 135 and degrees < 225:
		return GlobalEnums.FacingDirection.WALK_LEFT
	else:  # 225 to 315
		return GlobalEnums.FacingDirection.WALK_UP

func _get_idle_direction_from_walking(walk_dir: GlobalEnums.FacingDirection) -> GlobalEnums.FacingDirection:
	match walk_dir:
		GlobalEnums.FacingDirection.WALK_UP:
			return GlobalEnums.FacingDirection.IDLE_UP
		GlobalEnums.FacingDirection.WALK_DOWN:
			return GlobalEnums.FacingDirection.IDLE_DOWN
		GlobalEnums.FacingDirection.WALK_LEFT:
			return GlobalEnums.FacingDirection.IDLE_LEFT
		GlobalEnums.FacingDirection.WALK_RIGHT:
			return GlobalEnums.FacingDirection.IDLE_RIGHT
		_:
			return GlobalEnums.FacingDirection.IDLE_DOWN

func _physics_process(delta):
	state_timer += delta

	match current_state:
		GlobalEnums.CreatureState.IDLE:
			_handle_idle_state()
		GlobalEnums.CreatureState.WALKING:
			_handle_walking_state(delta)

	# Check if it's time to switch states
	if state_timer >= current_state_duration:
		_switch_state()

	emote_timer += delta
	if emote_timer >= next_emote_time and not current_emote_bubble:
		_show_emote_bubble()

func _show_emote_bubble():
	# Create and position emote bubble
	current_emote_bubble = EMOTE_BUBBLE.instantiate()
	add_child(current_emote_bubble)

	# Position above creature
	current_emote_bubble.position = Vector2(0, -20)  # Adjust Y offset as needed

	# Set random emote if the bubble has a method for it
	if current_emote_bubble.has_method("set_random_emote"):
		current_emote_bubble.set_random_emote()

	# Set timer for next emote
	emote_timer = 0.0
	next_emote_time = randf_range(min_emote_interval, max_emote_interval)

	# Auto-remove after duration
	get_tree().create_timer(emote_duration).timeout.connect(_hide_emote_bubble)

func _hide_emote_bubble():
	if current_emote_bubble:
		current_emote_bubble.queue_free()
		current_emote_bubble = null

func _handle_idle_state():
	# Stop movement
	velocity = Vector2.ZERO
	# Get idle direction based on current facing
	var idle_dir = _get_idle_direction_from_walking(facing_direction)
	var idle_animation = GlobalEnums.get_animation_name(idle_dir)

	if $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation(idle_animation):
		$AnimatedSprite2D.play(idle_animation)
	elif $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation("idle"):
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0

func _handle_walking_state(delta):
	# Check if we reached the target
	if position.distance_to(wander_target) < 10:
		# Reached target, switch to idle
		_switch_state()
		return

	# Move towards target
	var direction_vector = (wander_target - position).normalized()
	velocity = direction_vector * wander_speed

	# Determine direction and play animation
	facing_direction = _get_walking_direction(direction_vector)
	var animation_name = GlobalEnums.get_animation_name(facing_direction)

	if $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation(animation_name):
		$AnimatedSprite2D.play(animation_name)
		$AnimatedSprite2D.flip_h = false  # Reset flip since we're using directional animations
	elif $AnimatedSprite2D.sprite_frames and $AnimatedSprite2D.sprite_frames.has_animation("walk"):
		# Fallback to basic walk with flipping if directional animations don't exist
		$AnimatedSprite2D.play("walk")
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = false
		elif velocity.x < 0:
			$AnimatedSprite2D.flip_h = true

	move_and_slide()

	# Ensure we stay within bounds after movement
	position = _clamp_to_bounds(position)

func _switch_state():
	match current_state:
		GlobalEnums.CreatureState.IDLE:
			_start_walking_state()
		GlobalEnums.CreatureState.WALKING:
			_start_idle_state()

func _start_idle_state():
	current_state = GlobalEnums.CreatureState.IDLE
	state_timer = 0.0
	current_state_duration = randf_range(min_idle_time, max_idle_time)

func _start_walking_state():
	current_state = GlobalEnums.CreatureState.WALKING
	state_timer = 0.0
	current_state_duration = randf_range(min_walk_time, max_walk_time)
	_pick_new_wander_target()

func _pick_new_wander_target():
	if container_bounds.size == Vector2.ZERO:
		# If no bounds set yet, wander around current position
		var random_angle = randf() * TAU
		var random_distance = randf_range(50, 150)
		wander_target = position + Vector2(
			cos(random_angle) * random_distance,
			sin(random_angle) * random_distance
		)
	else:
		# Pick random point within container bounds
		wander_target = Vector2(
			randf_range(container_bounds.position.x, container_bounds.position.x + container_bounds.size.x),
			randf_range(container_bounds.position.y, container_bounds.position.y + container_bounds.size.y)
		)

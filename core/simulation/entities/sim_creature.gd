# core/simulation/entities/sim_creature.gd
extends Resource
class_name SimCreature

# Simulation ID
var sim_id: String = ""

# Reference to actual creature data
var creature_data: CreatureData

# Simulation state (no visuals!)
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var current_state: GlobalEnums.CreatureState = GlobalEnums.CreatureState.IDLE
var facing_direction: GlobalEnums.FacingDirection = GlobalEnums.FacingDirection.WALK_DOWN

# AI state
var wander_target: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var current_state_duration: float = 0.0
var container_bounds: Rect2 = Rect2(0, 0, 1920, 1080)

# AI parameters (moved from visual layer)
var wander_speed: float = 50.0
var min_walk_time: float = 2.0
var max_walk_time: float = 4.0
var min_idle_time: float = 1.0
var max_idle_time: float = 3.0

# Emote state (simulation decides, view renders)
var current_emote: int = -1  # -1 means no emote, otherwise GlobalEnums.Emote value
var emote_timer: float = 0.0
var next_emote_time: float = 0.0

func _init(data: CreatureData = null):
	if data:
		creature_data = data
		# Initialize AI timers
		next_emote_time = randf_range(5.0, 15.0)
		_start_idle_state()

func update_simulation(delta: float):
	# Update timers
	state_timer += delta
	emote_timer += delta

	# Process current state
	match current_state:
		GlobalEnums.CreatureState.IDLE:
			_process_idle_state(delta)
		GlobalEnums.CreatureState.WALKING:
			_process_walking_state(delta)

	# Check for emote trigger
	if emote_timer >= next_emote_time:
		_trigger_random_emote()

	# Clear expired emotes
	if current_emote >= 0 and emote_timer > 2.5:
		current_emote = -1  # Clear emote

func _process_idle_state(delta: float):
	if state_timer >= current_state_duration:
		_start_walking_state()

func _process_walking_state(delta: float):
	# Move towards target
	var direction = (wander_target - position).normalized()
	velocity = direction * wander_speed
	position += velocity * delta

	# Update facing direction based on movement
	facing_direction = _get_walking_direction(direction)

	# Check if reached target or time expired
	var distance_to_target = position.distance_to(wander_target)
	if distance_to_target < 5.0 or state_timer >= current_state_duration:
		_start_idle_state()

func _start_idle_state():
	current_state = GlobalEnums.CreatureState.IDLE
	state_timer = 0.0
	current_state_duration = randf_range(min_idle_time, max_idle_time)
	velocity = Vector2.ZERO

func _start_walking_state():
	current_state = GlobalEnums.CreatureState.WALKING
	state_timer = 0.0
	current_state_duration = randf_range(min_walk_time, max_walk_time)
	_pick_new_wander_target()

func _pick_new_wander_target():
	wander_target = Vector2(
		randf_range(container_bounds.position.x + 50,
		           container_bounds.position.x + container_bounds.size.x - 50),
		randf_range(container_bounds.position.y + 50,
		           container_bounds.position.y + container_bounds.size.y - 50)
	)

func _get_walking_direction(direction: Vector2) -> GlobalEnums.FacingDirection:
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	if degrees >= 315 or degrees < 45:
		return GlobalEnums.FacingDirection.WALK_RIGHT
	elif degrees >= 45 and degrees < 135:
		return GlobalEnums.FacingDirection.WALK_DOWN
	elif degrees >= 135 and degrees < 225:
		return GlobalEnums.FacingDirection.WALK_LEFT
	else:
		return GlobalEnums.FacingDirection.WALK_UP

func _trigger_random_emote():
	var emotes = GlobalEnums.Emote.values()
	current_emote = emotes[randi() % emotes.size()]
	emote_timer = 0.0
	next_emote_time = randf_range(5.0, 15.0)
	# Note: SimulationManager will detect the emote change and emit event

# core/simulation/simulation_manager.gd
extends Node
# Note: No class_name to avoid conflict with autoload singleton

# Simulation state
var simulation_running: bool = false
var simulation_tick: int = 0
var tick_rate: float = 30.0  # Ticks per second
var time_accumulator: float = 0.0

# Entity registries
var sim_creatures: Dictionary = {}  # {id: SimCreature}
var sim_facilities: Dictionary = {}  # {id: SimFacility}
var sim_activities: Dictionary = {}  # {id: SimActivity}

# Simulation events queue (for view layer to consume)
var event_queue: Array = []

signal simulation_tick_completed(tick: int)
signal simulation_event_emitted(event: Dictionary)

func _ready():
	set_process(false)  # Start paused
	print("SimulationManager initialized")

func start_simulation():
	simulation_running = true
	set_process(true)
	print("Simulation started")

func stop_simulation():
	simulation_running = false
	set_process(false)
	print("Simulation stopped")

func _process(delta: float):
	if not simulation_running:
		return

	# Fixed timestep simulation
	time_accumulator += delta
	var tick_duration = 1.0 / tick_rate

	while time_accumulator >= tick_duration:
		_simulate_tick()
		time_accumulator -= tick_duration

func _simulate_tick():
	simulation_tick += 1

	# Process all simulation systems in deterministic order
	_process_creature_ai()
	_process_facilities()
	_process_activities()

	simulation_tick_completed.emit(simulation_tick)

func _process_creature_ai():
	for sim_id in sim_creatures.keys():
		var creature = sim_creatures[sim_id]
		var prev_emote = creature.current_emote
		creature.update_simulation(1.0 / tick_rate)
		# Emit event if emote changed
		if prev_emote != creature.current_emote and creature.current_emote >= 0:
			emit_sim_event("creature_emote", {"id": sim_id, "emote": creature.current_emote})

func _process_facilities():
	# Process facility logic
	pass

func _process_activities():
	# Process activity logic
	pass

func emit_sim_event(event_type: String, data: Dictionary):
	var event = {
		"type": event_type,
		"tick": simulation_tick,
		"data": data
	}
	event_queue.append(event)
	simulation_event_emitted.emit(event)

func register_creature(creature: SimCreature) -> String:
	var id = generate_unique_id()
	sim_creatures[id] = creature
	creature.sim_id = id
	emit_sim_event("creature_spawned", {"id": id, "position": creature.position})
	return id

func unregister_creature(id: String):
	if sim_creatures.has(id):
		sim_creatures.erase(id)
		emit_sim_event("creature_removed", {"id": id})

func generate_unique_id() -> String:
	return "sim_" + str(Time.get_ticks_msec()) + "_" + str(randi())

# core/view/view_manager.gd
extends Node
# Note: No class_name to avoid conflict with autoload singleton

# View registries
var creature_views: Dictionary = {}  # {sim_id: CreatureView}
var facility_views: Dictionary = {}  # {sim_id: FacilityView}

# Reference to simulation
var simulation_manager: Node  # SimulationManager (can't use class_name due to autoload)

func _ready():
	# Get simulation manager reference
	if has_node("/root/SimulationManager"):
		simulation_manager = get_node("/root/SimulationManager")
		simulation_manager.simulation_event_emitted.connect(_on_simulation_event)
		simulation_manager.simulation_tick_completed.connect(_on_simulation_tick)
	print("ViewManager initialized")

func _on_simulation_event(event: Dictionary):
	match event.type:
		"creature_spawned":
			_create_creature_view(event.data.id, event.data.position)
		"creature_removed":
			_remove_creature_view(event.data.id)
		"creature_emote":
			_update_creature_emote(event.data.id, event.data.emote)

func _on_simulation_tick(tick: int):
	# Update all views based on simulation state
	_update_all_creature_views()

func _update_all_creature_views():
	if not simulation_manager:
		return

	for sim_id in simulation_manager.sim_creatures:
		var sim_creature = simulation_manager.sim_creatures[sim_id]
		if creature_views.has(sim_id):
			var view = creature_views[sim_id]
			view.update_from_simulation(sim_creature)

func _create_creature_view(sim_id: String, position: Vector2):
	# This will create the visual representation
	# For now, just track that we need to create it
	print("Need to create view for creature: ", sim_id)

func _remove_creature_view(sim_id: String):
	if creature_views.has(sim_id):
		creature_views[sim_id].queue_free()
		creature_views.erase(sim_id)

func _update_creature_emote(sim_id: String, emote: int):  # Emote as int (GlobalEnums.Emote value)
	if creature_views.has(sim_id):
		creature_views[sim_id].show_emote(emote)

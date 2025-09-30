# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_data: PlayerData
var facility_manager: FacilityManager

const SAVE_PATH = "user://savegame.tres"

func _ready():
	_connect_signals()
	_create_managers()
	
func _create_managers():
	facility_manager = FacilityManager.new()
	facility_manager.name = "FacilityManager"
	add_child(facility_manager)

func _connect_signals():
	SignalBus.game_started.connect(initialize_new_game)
	
func initialize_new_game():
	# Create player data container
	player_data = PlayerData.new()
	player_data.gold = 100

	# Create starter creature with proper species
	var starter_creature = CreatureData.new()
	starter_creature.creature_name = "Scuttle"
	starter_creature.species = GlobalEnums.Species.SCUTTLEGUARD
	starter_creature.strength = 10
	starter_creature.agility = 8
	starter_creature.intelligence = 6
	
	player_data.creatures.append(starter_creature)
	SignalBus.creature_added.emit(starter_creature)
	
	starter_creature = CreatureData.new()
	starter_creature.creature_name = "Squish"
	starter_creature.species = GlobalEnums.Species.SLIME
	starter_creature.strength = 10
	starter_creature.agility = 8
	starter_creature.intelligence = 6
	
	player_data.creatures.append(starter_creature)

	# Use SignalBus instead of local signals
	SignalBus.player_data_initialized.emit()
	SignalBus.creature_added.emit(starter_creature)
	SignalBus.gold_changed.emit(player_data.gold)
	
	create_test_facility()

func advance_week():
	current_week += 1
	print("Advancing to week ", current_week)

	# Process all facility activities through facility manager
	if facility_manager:
		facility_manager.process_all_activities(current_week)

	SignalBus.week_advanced.emit(current_week)

	# Save after week advancement
	if has_node("/root/SaveManager"):
		SaveManager.save_game()
#
func create_test_facility() -> void:
	# Create a training facility with multiple activities
	var training_facility = FacilityResource.new()
	training_facility.facility_name = "Training Grounds"
	training_facility.description = "A place to train creatures"
	training_facility.max_creatures = 3

	# Add strength training activity
	var strength_activity = preload("res://resources/activities/strength_training.gd").new()
	strength_activity.strength_gain = 10

	# Add species change activity
	var transform_activity = preload("res://resources/activities/species_change.gd").new()
	transform_activity.target_species = GlobalEnums.Species.WIND_DANCER

	training_facility.activities.append(strength_activity)
	training_facility.activities.append(transform_activity)

	# Test on first creature
	if player_data and player_data.creatures.size() > 0:
		print("Testing facility on ", player_data.creatures[0].creature_name)
		training_facility.run_all_activities(player_data.creatures[0])
		
func get_active_creature() -> CreatureData:
	if player_data and player_data.creatures.size() > 0:
		return player_data.creatures[0]
	return null

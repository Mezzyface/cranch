# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_data: PlayerData
var facility_manager: FacilityManager
var quest_manager: QuestManager
var inventory_manager: InventoryManager

const SAVE_PATH = "user://savegame.tres"

func _ready():
	_connect_signals()
	_create_managers()
	
func _create_managers():
	facility_manager = FacilityManager.new()
	facility_manager.name = "FacilityManager"
	add_child(facility_manager)

	quest_manager = QuestManager.new()
	quest_manager.name = "QuestManager"
	add_child(quest_manager)

func _connect_signals():
	SignalBus.game_started.connect(initialize_new_game)
	SignalBus.gold_change_requested.connect(_on_gold_change_requested)
	
func initialize_new_game():
	# Create player data container
	player_data = PlayerData.new()
	player_data.gold = 1000

	# Initialize inventory manager
	inventory_manager = InventoryManager.new(player_data)

	# Give starter food
	inventory_manager.add_item("food_basic", 20)

	# Generate starter creatures using CreatureGenerator
	var starter_1 = CreatureGenerator.generate_creature(
		GlobalEnums.Species.GUARD_ROBOT,
		"Steel"  # Guard Robot starter
	)
	player_data.creatures.append(starter_1)
	SignalBus.creature_added.emit(starter_1)

	var starter_2 = CreatureGenerator.generate_creature(
		GlobalEnums.Species.KRIP,
		"Mysty"  # Balanced Krip starter
	)
	player_data.creatures.append(starter_2)
	SignalBus.creature_added.emit(starter_2)

	# Use SignalBus instead of local signals
	SignalBus.player_data_initialized.emit()
	SignalBus.gold_changed.emit(player_data.gold)

	# Initialize quest manager
	quest_manager.initialize()

	create_test_facility()

# Helper function to add a generated creature to player's collection
func add_generated_creature(species: GlobalEnums.Species, creature_name: String = "") -> CreatureData:
	var creature = CreatureGenerator.generate_creature(species, creature_name)
	player_data.creatures.append(creature)
	SignalBus.creature_added.emit(creature)
	return creature

# Remove a creature from player's collection
func remove_creature(creature: CreatureData):
	if player_data and creature in player_data.creatures:
		player_data.creatures.erase(creature)
		SignalBus.creature_removed.emit(creature)
		print("Removed creature: ", creature.creature_name)
	
func advance_week():
	# Check if all creatures have food assigned
	if not facility_manager.all_creatures_have_food():
		var missing = facility_manager.get_creatures_missing_food()
		SignalBus.week_advancement_blocked.emit("Some creatures need food!", missing)
		print("Cannot advance week: %d creatures need food" % missing.size())
		return

	current_week += 1
	print("Advancing to week ", current_week)

	# Process all facility activities through facility manager
	if facility_manager:
		facility_manager.process_all_activities(current_week)

	# Check for creature deaths
	_check_creature_lifespans()

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
	strength_activity.strength_gain = 50

	# Add species change activity
	var transform_activity = preload("res://resources/activities/species_change.gd").new()
	transform_activity.target_species = GlobalEnums.Species.ILLUSIONARY_RACCOON

	training_facility.activities.append(strength_activity)
	training_facility.activities.append(transform_activity)

	# Create competition stadium
	var stadium = load("res://resources/facilities/competition_stadium.tres") as FacilityResource
	if stadium:
		print("Competition Stadium loaded: ", stadium.facility_name)
	else:
		push_warning("Failed to load competition stadium resource")

func get_active_creature() -> CreatureData:
	if player_data and player_data.creatures.size() > 0:
		return player_data.creatures[0]
	return null

func _on_gold_change_requested(amount: int):
	if not player_data:
		push_error("Cannot change gold: no player_data")
		return

	player_data.gold += amount

	# Prevent negative gold
	if player_data.gold < 0:
		player_data.gold = 0

	# Emit update signal for UI
	SignalBus.gold_changed.emit(player_data.gold)

	if amount > 0:
		print("Gained %d gold (Total: %d)" % [amount, player_data.gold])
	else:
		print("Spent %d gold (Total: %d)" % [-amount, player_data.gold])

func _check_creature_lifespans() -> void:
	if not player_data:
		return

	var creatures_to_remove: Array[CreatureData] = []

	for creature in player_data.creatures:
		var age = creature.get_age(current_week)
		var remaining = creature.get_remaining_lifespan(current_week)

		# Check if creature died of old age
		if creature.is_dead(current_week):
			print("%s died of old age at %d weeks" % [creature.creature_name, age])
			SignalBus.creature_died.emit(creature, "old_age")
			creatures_to_remove.append(creature)

		# Warn if creature is nearing death (5 weeks or less)
		elif remaining <= 5 and remaining > 0:
			SignalBus.creature_nearing_death.emit(creature, remaining)

	# Remove dead creatures
	for creature in creatures_to_remove:
		remove_creature(creature)

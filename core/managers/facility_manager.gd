# core/facility_manager.gd
extends Node
class_name FacilityManager

# Dictionary to track which creatures are assigned to which facilities
var facility_assignments: Dictionary = {}  # {facility: [creatures]}
var active_facilities: Array[FacilityResource] = []

# Track food assigned to each creature in facilities
# Format: {creature: item_id} or {creature: null} if no food assigned
var _creature_food_assignments: Dictionary = {}

func _init():
	# Listen for creature removal to auto-unassign from facilities
	# Use _init instead of _ready to ensure signal is connected before any creature removal
	pass

func _ready():
	# Connect to signal once in the scene tree
	if not SignalBus.creature_removed.is_connected(_on_creature_removed):
		SignalBus.creature_removed.connect(_on_creature_removed)
		print("FacilityManager: Connected to creature_removed signal")

func register_assignment(creature: CreatureData, facility: FacilityResource):
	# Store the assignment but don't run activities yet
	if not facility_assignments.has(facility):
		facility_assignments[facility] = []

	if not facility in active_facilities:
		active_facilities.append(facility)

	if not creature in facility_assignments[facility]:
		facility_assignments[facility].append(creature)
		print("Registered ", creature.creature_name, " to ", facility.facility_name, " for training")

func unregister_assignment(creature: CreatureData, facility: FacilityResource):
	# Remove creature from facility assignment
	if facility_assignments.has(facility):
		if creature in facility_assignments[facility]:
			facility_assignments[facility].erase(creature)
			print("Unregistered ", creature.creature_name, " from ", facility.facility_name)

			# Clean up food assignment
			unassign_food_from_creature(creature)

			# If facility has no more creatures, remove it from active facilities
			if facility_assignments[facility].is_empty():
				facility_assignments.erase(facility)
				active_facilities.erase(facility)

func process_all_activities(week: int):
	print("Week ", week, " - Processing all facility activities")

	# This should only be called after validation ensures all creatures have food
	for facility in facility_assignments:
		var creatures = facility_assignments[facility]

		for creature in creatures:
			# Get and consume assigned food
			var food_item_id = get_assigned_food(creature)
			if food_item_id.is_empty():
				push_error("Creature %s has no food assigned - this should be prevented!" % creature.creature_name)
				continue

			# Remove food from inventory
			if not GameManager.inventory_manager.remove_item(food_item_id, 1):
				push_error("Failed to remove food %s from inventory" % food_item_id)
				continue

			# Get stat boost multiplier from food (for future enhancement)
			var food_resource = GameManager.inventory_manager.get_item_resource(food_item_id)
			var stat_multiplier = 1.0
			if food_resource:
				stat_multiplier = food_resource.stat_boost_multiplier

			# Process activities (in future, pass stat_multiplier to activities)
			print("Training ", creature.creature_name, " at ", facility.facility_name, " with ", food_item_id, " (", stat_multiplier, "x)")
			facility.run_all_activities(creature)

			# Clear food assignment after consumption
			unassign_food_from_creature(creature)

func get_facility_for_creature(creature: CreatureData) -> FacilityResource:
	for facility in facility_assignments:
		if creature in facility_assignments[facility]:
			return facility
	return null

func clear_all_assignments():
	facility_assignments.clear()
	active_facilities.clear()

func _on_creature_removed(creature: CreatureData):
	print("FacilityManager: _on_creature_removed called for: ", creature.creature_name)
	print("Current facility_assignments: ", facility_assignments.keys())

	# Automatically unassign creature from any facilities when removed
	for facility in facility_assignments.keys():
		print("Checking facility: ", facility.facility_name, " creatures: ", facility_assignments[facility])
		if creature in facility_assignments[facility]:
			print("Found creature in facility, unregistering...")
			unregister_assignment(creature, facility)
			# Emit signal so FacilityCard can update its visual display
			SignalBus.facility_unassigned.emit(creature, facility)
			print("Auto-unassigned removed creature from facility: ", facility.facility_name)

# Assign food to a creature in a facility
func assign_food_to_creature(creature: CreatureData, item_id: String):
	_creature_food_assignments[creature] = item_id
	SignalBus.creature_food_assigned.emit(creature, item_id)
	print("Assigned food '%s' to creature '%s'" % [item_id, creature.creature_name])

# Remove food assignment from creature
func unassign_food_from_creature(creature: CreatureData):
	if _creature_food_assignments.has(creature):
		_creature_food_assignments.erase(creature)
		SignalBus.creature_food_unassigned.emit(creature)

# Check if creature has food assigned
func has_food_assigned(creature: CreatureData) -> bool:
	return _creature_food_assignments.has(creature) and _creature_food_assignments[creature] != null

# Get food assigned to creature
func get_assigned_food(creature: CreatureData) -> String:
	return _creature_food_assignments.get(creature, "")

# Check if all creatures in facilities have food assigned
func all_creatures_have_food() -> bool:
	for facility in facility_assignments.keys():
		var creatures = facility_assignments[facility]
		for creature in creatures:
			if not has_food_assigned(creature):
				return false
	return true

# Get list of creatures missing food
func get_creatures_missing_food() -> Array[CreatureData]:
	var missing: Array[CreatureData] = []
	for facility in facility_assignments.keys():
		var creatures = facility_assignments[facility]
		for creature in creatures:
			if not has_food_assigned(creature):
				missing.append(creature)
	return missing

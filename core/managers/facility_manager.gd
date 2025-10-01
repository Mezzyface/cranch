# core/facility_manager.gd
extends Node
class_name FacilityManager

# Dictionary to track which creatures are assigned to which facilities
var facility_assignments: Dictionary = {}  # {facility: [creatures]}
var active_facilities: Array[FacilityResource] = []

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

			# If facility has no more creatures, remove it from active facilities
			if facility_assignments[facility].is_empty():
				facility_assignments.erase(facility)
				active_facilities.erase(facility)

func process_all_activities(week: int):
	print("Week ", week, " - Processing all facility activities")

	# Process all facilities
	for facility in facility_assignments:
		var creatures = facility_assignments[facility]
		for creature in creatures:
			print("Training ", creature.creature_name, " at ", facility.facility_name)
			facility.run_all_activities(creature)

	# Optional: Clear assignments after processing
	# facility_assignments.clear()

func get_facility_for_creature(creature: CreatureData) -> FacilityResource:
	for facility in facility_assignments:
		if creature in facility_assignments[facility]:
			return facility
	return null

func clear_all_assignments():
	facility_assignments.clear()
	active_facilities.clear()

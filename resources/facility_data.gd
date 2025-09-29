# resources/facility_data.gd
extends Resource
class_name FacilityResource

@export var facility_name: String = "Unnamed Facility"
@export var description: String = ""
@export var activities: Array[ActivityResource] = []
@export var max_creatures: int = 1

# Run all activities on a creature
func run_all_activities(creature: CreatureData) -> void:
	for activity in activities:
		if activity and activity.can_run(creature):
			activity.run_activity(creature)
			print("Running activity: ", activity.activity_name, " on ", creature.creature_name)

# Run specific activity by index
func run_activity_at(creature: CreatureData, index: int) -> void:
	if index >= 0 and index < activities.size():
		var activity = activities[index]
		if activity and activity.can_run(creature):
			activity.run_activity(creature)

# Check if facility has space
func has_space(current_creatures: int) -> bool:
	return current_creatures < max_creatures

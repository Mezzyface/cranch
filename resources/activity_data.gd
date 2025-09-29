# resources/activity_data.gd
extends Resource
class_name ActivityResource

@export var activity_name: String = "Unnamed Activity"
@export var description: String = ""
@export var duration_weeks: int = 1

# Override this in child classes for custom behavior
func run_activity(creature: CreatureData) -> void:
	push_warning("run_activity not implemented for " + activity_name)
	pass

# Override to check if activity can be performed
func can_run(creature: CreatureData) -> bool:
	return true

# Override to provide preview text for UI
func get_preview_text(creature: CreatureData) -> String:
	return description

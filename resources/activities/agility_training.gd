# resources/activities/agility_training.gd
extends ActivityResource
class_name AgilityTrainingActivity

@export var agility_gain: int = 35

func _init():
	activity_name = "Agility Training"
	description = "Increases creature's agility by 35"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_agility = creature.agility
	creature.agility = min(1000, creature.agility + agility_gain)  # Cap at 1000
	var actual_gain = creature.agility - old_agility
	print(creature.creature_name, " gained ", actual_gain, " agility! (", old_agility, " -> ", creature.agility, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	var potential_gain = min(agility_gain, 1000 - creature.agility)
	return "Will gain +" + str(potential_gain) + " agility"

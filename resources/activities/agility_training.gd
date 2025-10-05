# resources/activities/agility_training.gd
extends ActivityResource
class_name AgilityTrainingActivity

@export var agility_gain: int = 50

func _init():
	activity_name = "Agility Training"
	description = "Increases creature's agility by 50"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_agility = creature.agility
	creature.agility += agility_gain
	print(creature.creature_name, " gained ", agility_gain, " agility! (", old_agility, " -> ", creature.agility, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(agility_gain) + " agility"

# resources/activities/intelligence_training.gd
extends ActivityResource
class_name IntelligenceTrainingActivity

@export var intelligence_gain: int = 50

func _init():
	activity_name = "Intelligence Training"
	description = "Increases creature's intelligence by 50"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_intelligence = creature.intelligence
	creature.intelligence += intelligence_gain
	print(creature.creature_name, " gained ", intelligence_gain, " intelligence! (", old_intelligence, " -> ", creature.intelligence, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(intelligence_gain) + " intelligence"

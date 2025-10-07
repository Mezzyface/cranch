# resources/activities/intelligence_training.gd
extends ActivityResource
class_name IntelligenceTrainingActivity

@export var intelligence_gain: int = 35

func _init():
	activity_name = "Intelligence Training"
	description = "Increases creature's intelligence by 35"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_intelligence = creature.intelligence
	creature.intelligence = min(1000, creature.intelligence + intelligence_gain)  # Cap at 1000
	var actual_gain = creature.intelligence - old_intelligence
	print(creature.creature_name, " gained ", actual_gain, " intelligence! (", old_intelligence, " -> ", creature.intelligence, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	var potential_gain = min(intelligence_gain, 1000 - creature.intelligence)
	return "Will gain +" + str(potential_gain) + " intelligence"

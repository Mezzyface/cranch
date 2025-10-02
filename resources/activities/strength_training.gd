# resources/activities/strength_training.gd
extends ActivityResource
class_name StrengthTrainingActivity

@export var strength_gain: int = 5

func _init():
	activity_name = "Strength Training"
	description = "Increases creature's strength"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_strength = creature.strength
	creature.strength += strength_gain
	print(creature.creature_name, " gained ", strength_gain, " strength! (", old_strength, " -> ", creature.strength, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(strength_gain) + " strength"

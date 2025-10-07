# resources/activities/strength_training.gd
extends ActivityResource
class_name StrengthTrainingActivity

@export var strength_gain: int = 35

func _init():
	activity_name = "Strength Training"
	description = "Increases creature's strength by 35"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_strength = creature.strength
	creature.strength = min(1000, creature.strength + strength_gain)  # Cap at 1000
	var actual_gain = creature.strength - old_strength
	print(creature.creature_name, " gained ", actual_gain, " strength! (", old_strength, " -> ", creature.strength, ")")

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	var potential_gain = min(strength_gain, 1000 - creature.strength)
	return "Will gain +" + str(potential_gain) + " strength"

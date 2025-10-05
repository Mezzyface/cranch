# resources/activities/power_training.gd
extends ActivityResource
class_name PowerTrainingActivity

@export var strength_gain: int = 75
@export var agility_loss: int = 15

func _init():
	activity_name = "Power Training"
	description = "Intensive strength training (+75 STR, -15 AGI)"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_str = creature.strength
	var old_agi = creature.agility

	creature.strength += strength_gain
	creature.agility = max(0, creature.agility - agility_loss)

	print(creature.creature_name, " completed Power Training! STR: ", old_str, "->", creature.strength, " AGI: ", old_agi, "->", creature.agility)

	TagManager.auto_grant_training_tags(creature)

	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(strength_gain) + " strength, lose -" + str(agility_loss) + " agility"

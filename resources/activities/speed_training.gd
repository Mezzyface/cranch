# resources/activities/speed_training.gd
extends ActivityResource
class_name SpeedTrainingActivity

@export var agility_gain: int = 75
@export var strength_loss: int = 15

func _init():
	activity_name = "Speed Training"
	description = "Intensive agility training (+75 AGI, -15 STR)"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_agi = creature.agility
	var old_str = creature.strength

	creature.agility += agility_gain
	creature.strength = max(0, creature.strength - strength_loss)

	print(creature.creature_name, " completed Speed Training! AGI: ", old_agi, "->", creature.agility, " STR: ", old_str, "->", creature.strength)

	TagManager.auto_grant_training_tags(creature)

	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(agility_gain) + " agility, lose -" + str(strength_loss) + " strength"

# resources/activities/tactical_training.gd
extends ActivityResource
class_name TacticalTrainingActivity

@export var intelligence_gain: int = 75
@export var strength_loss: int = 15

func _init():
	activity_name = "Tactical Training"
	description = "Mental conditioning (+75 INT, -15 STR)"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_int = creature.intelligence
	var old_str = creature.strength

	creature.intelligence += intelligence_gain
	creature.strength = max(0, creature.strength - strength_loss)

	print(creature.creature_name, " completed Tactical Training! INT: ", old_int, "->", creature.intelligence, " STR: ", old_str, "->", creature.strength)

	TagManager.auto_grant_training_tags(creature)

	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(intelligence_gain) + " intelligence, lose -" + str(strength_loss) + " strength"

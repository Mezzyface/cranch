# resources/activities/balanced_training.gd
extends ActivityResource
class_name BalancedTrainingActivity

@export var stat_gain: int = 20

func _init():
	activity_name = "Balanced Training"
	description = "Increases all stats by 20"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_str = creature.strength
	var old_agi = creature.agility
	var old_int = creature.intelligence

	creature.strength = min(1000, creature.strength + stat_gain)
	creature.agility = min(1000, creature.agility + stat_gain)
	creature.intelligence = min(1000, creature.intelligence + stat_gain)

	print(creature.creature_name, " gained ", stat_gain, " to all stats! STR: ", old_str, "->", creature.strength, " AGI: ", old_agi, "->", creature.agility, " INT: ", old_int, "->", creature.intelligence)

	# Auto-grant training tags if creature now qualifies
	TagManager.auto_grant_training_tags(creature)

	# Emit signal through SignalBus if needed
	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(stat_gain) + " to all stats"

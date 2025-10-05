# resources/activities/rest_activity.gd
extends ActivityResource
class_name RestActivity

@export var stat_gain: int = 20

func _init():
	activity_name = "Rest & Recovery"
	description = "Gentle recovery training (+20 all stats)"
	duration_weeks = 1

func run_activity(creature: CreatureData) -> void:
	var old_str = creature.strength
	var old_agi = creature.agility
	var old_int = creature.intelligence

	creature.strength += stat_gain
	creature.agility += stat_gain
	creature.intelligence += stat_gain

	print(creature.creature_name, " rested and recovered! All stats +", stat_gain)

	TagManager.auto_grant_training_tags(creature)

	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	return "Will gain +" + str(stat_gain) + " to all stats (gentle training)"

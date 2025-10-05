# resources/activities/extreme_training.gd
extends ActivityResource
class_name ExtremeTrainingActivity

@export var primary_stat_gain: int = 100
@export var secondary_stat_gain: int = 50

func _init():
	activity_name = "Extreme Training"
	description = "Intense specialized training based on creature's natural strengths"
	duration_weeks = 2

func run_activity(creature: CreatureData) -> void:
	# Find the creature's highest stat
	var highest_stat = "strength"
	var highest_value = creature.strength

	if creature.agility > highest_value:
		highest_stat = "agility"
		highest_value = creature.agility

	if creature.intelligence > highest_value:
		highest_stat = "intelligence"
		highest_value = creature.intelligence

	# Train based on highest stat
	match highest_stat:
		"strength":
			creature.strength += primary_stat_gain
			creature.agility += secondary_stat_gain
			print(creature.creature_name, " completed Extreme Power Training! STR +", primary_stat_gain, ", AGI +", secondary_stat_gain)
		"agility":
			creature.agility += primary_stat_gain
			creature.intelligence += secondary_stat_gain
			print(creature.creature_name, " completed Extreme Speed Training! AGI +", primary_stat_gain, ", INT +", secondary_stat_gain)
		"intelligence":
			creature.intelligence += primary_stat_gain
			creature.strength += secondary_stat_gain
			print(creature.creature_name, " completed Extreme Mental Training! INT +", primary_stat_gain, ", STR +", secondary_stat_gain)

	TagManager.auto_grant_training_tags(creature)

	if SignalBus.has_signal("creature_stats_changed"):
		SignalBus.creature_stats_changed.emit(creature)

func get_preview_text(creature: CreatureData) -> String:
	var highest_stat = "Strength"
	var highest_value = creature.strength

	if creature.agility > highest_value:
		highest_stat = "Agility"
		highest_value = creature.agility

	if creature.intelligence > highest_value:
		highest_stat = "Intelligence"

	return "Will boost " + highest_stat + " (+" + str(primary_stat_gain) + ") and secondary stat (+" + str(secondary_stat_gain) + ")"

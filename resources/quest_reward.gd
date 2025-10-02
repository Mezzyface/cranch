# resources/quest_reward.gd
extends Resource
class_name QuestReward

@export var gold: int = 0
@export var experience: int = 0

# Future: Item rewards
# @export var items: Array[ItemResource] = []

# Special unlocks (e.g., "Unlocked new facility", "Gained Master Collector title")
@export var unlock_message: String = ""

func has_rewards() -> bool:
	return gold > 0 or experience > 0 or unlock_message != ""

func get_description() -> String:
	var parts: Array[String] = []

	if gold > 0:
		parts.append("%d Gold" % gold)
	if experience > 0:
		parts.append("%d XP" % experience)
	if unlock_message != "":
		parts.append(unlock_message)

	return "\n".join(parts)

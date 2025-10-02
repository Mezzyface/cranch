# resources/quest_resource.gd
extends Resource
class_name QuestResource

# Quest identification
@export var quest_id: String = ""
@export var quest_title: String = "Untitled Quest"
@export var quest_giver: String = "Unknown"

# Quest content
@export_multiline var description: String = ""
@export_multiline var dialogue: String = ""

# Quest chain
@export var prerequisite_quest_ids: Array[String] = []

# Requirements (can have multiple parts)
@export var requirements: Array[QuestRequirement] = []

# Rewards
@export var reward: QuestReward = null

# Check if player meets prerequisites
func prerequisites_met(completed_quest_ids: Array[String]) -> bool:
	for prereq_id in prerequisite_quest_ids:
		if not prereq_id in completed_quest_ids:
			return false
	return true

# Validate if provided creatures meet all requirements
# Returns: { "valid": bool, "missing": Array[String] }
func validate_creatures(creatures: Array[CreatureData]) -> Dictionary:
	var result = {
		"valid": true,
		"missing": []
	}

	for req in requirements:
		var matching_count = 0

		# Count how many creatures match this requirement
		for creature in creatures:
			if req.creature_matches(creature):
				matching_count += 1
				if matching_count >= req.quantity:
					break

		# Check if we have enough
		if matching_count < req.quantity:
			var needed = req.quantity - matching_count
			result.valid = false
			result.missing.append("Need %d more: %s" % [needed, req.get_description()])

	return result

# Get total requirements summary for UI
func get_requirements_summary() -> String:
	var parts: Array[String] = []
	for i in range(requirements.size()):
		var req = requirements[i]
		if requirements.size() > 1:
			parts.append("Part %d: %dx %s" % [i + 1, req.quantity, req.get_description()])
		else:
			parts.append("%dx %s" % [req.quantity, req.get_description()])
	return "\n".join(parts)

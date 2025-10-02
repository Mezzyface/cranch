# resources/quest_requirement.gd
extends Resource
class_name QuestRequirement

# How many creatures needed with these requirements
@export var quantity: int = 1

# Optional species filter (null = any species)
@export var species_filter: GlobalEnums.Species = -1  # -1 means no filter

# Stat requirements (0 = no requirement)
@export var min_strength: int = 0
@export var min_agility: int = 0
@export var min_intelligence: int = 0

# Tags for future extensibility (e.g., ["Small", "Territorial"])
@export var required_tags: Array[String] = []

# Description of this requirement (for UI display)
@export var requirement_description: String = ""

# Check if a creature meets this requirement
func creature_matches(creature: CreatureData) -> bool:
	# Check species filter
	if species_filter != -1 and creature.species != species_filter:
		return false

	# Check stat minimums
	if creature.strength < min_strength:
		return false
	if creature.agility < min_agility:
		return false
	if creature.intelligence < min_intelligence:
		return false

	# Future: Check tags when implemented
	# for tag in required_tags:
	#     if not creature.has_tag(tag):
	#         return false

	return true

# Get a human-readable description of requirements
func get_description() -> String:
	if requirement_description != "":
		return requirement_description

	var parts: Array[String] = []

	# Species
	if species_filter != -1:
		var species_name = GlobalEnums.Species.keys()[species_filter]
		parts.append(species_name.capitalize())
	else:
		parts.append("Any Species")

	# Stats
	var stat_parts: Array[String] = []
	if min_strength > 0:
		stat_parts.append("STR ≥ %d" % min_strength)
	if min_agility > 0:
		stat_parts.append("AGI ≥ %d" % min_agility)
	if min_intelligence > 0:
		stat_parts.append("INT ≥ %d" % min_intelligence)

	if stat_parts.size() > 0:
		parts.append(" | ".join(stat_parts))

	# Tags
	if required_tags.size() > 0:
		parts.append("[" + ", ".join(required_tags) + "]")

	return " - ".join(parts)

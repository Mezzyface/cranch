@tool
extends EditorScript

# Run this script in Godot Editor: File -> Run
# Updates old quests to use 1000-point stat scale and new species

func _run():
	print("Updating old quest resources to new stat scale...")

	# These are the old quests that need updating
	# Old stats were on 1-20 scale, multiply by 50 for new scale

	# COL-01: Scuttleguard (now Guard Robot) with STR >= 15 -> 750
	update_quest("COL-01", "Mechanical Guardian", "The Collector",
		"The Collector needs a strong guardian.",
		"I need a strong guardian to protect my treasures. A Guard Robot would be perfect—something with real strength!",
		GlobalEnums.Species.GUARD_ROBOT, 750, 0, 0, 500)

	# COL-02: Slime (now Krip) - balanced creature
	update_quest("COL-02", "The Balanced One", "The Collector",
		"The Collector seeks a balanced creature.",
		"I need a creature with balanced abilities. Krip are known for their perfect equilibrium!",
		GlobalEnums.Species.KRIP, 450, 450, 450, 600)

	# COL-03: Wind Dancer (now Illusionary Raccoon) - high INT
	update_quest("COL-03", "The Mind Master", "The Collector",
		"The Collector wants an intelligent creature.",
		"Intelligence is what I seek. An Illusionary Raccoon with sharp wit would be ideal!",
		GlobalEnums.Species.ILLUSIONARY_RACCOON, 0, 0, 550, 700)

	# COL-04: Any creature with high stats (sequel quest)
	update_quest("COL-04", "The Ultimate Specimen", "The Collector",
		"The Collector's final request.",
		"I need the ultimate creature - balanced power across all attributes. At least 600 in each stat!",
		-1, 600, 600, 600, 1500, ["COL-03"])

	# COL-05: Multiple creatures (advanced quest)
	update_quest_multi("COL-05", "The Collection Complete", "The Collector",
		"The Collector wants variety.",
		"My collection needs diversity! Bring me three different powerful creatures!",
		[
			[GlobalEnums.Species.GUARD_ROBOT, 600, 0, 0],
			[GlobalEnums.Species.NEON_BAT, 0, 600, 0],
			[GlobalEnums.Species.STOPLIGHT_GHOST, 0, 0, 600]
		],
		2000, ["COL-04"])

	print("Old quest update complete!")

func update_quest(
	quest_id: String,
	title: String,
	giver: String,
	description: String,
	dialogue: String,
	species: int,
	min_str: int,
	min_agi: int,
	min_int: int,
	gold_reward: int,
	prerequisites: Array = []
) -> void:
	var requirement = QuestRequirement.new()
	requirement.quantity = 1
	requirement.species_filter = species
	requirement.min_strength = min_str
	requirement.min_agility = min_agi
	requirement.min_intelligence = min_int

	var reward = QuestReward.new()
	reward.gold = gold_reward

	var quest = QuestResource.new()
	quest.quest_id = quest_id
	quest.quest_title = title
	quest.quest_giver = giver
	quest.description = description
	quest.dialogue = dialogue
	quest.prerequisite_quest_ids.assign(prerequisites)
	quest.requirements.assign([requirement])
	quest.reward = reward

	var path = "res://resources/quests/" + quest_id + ".tres"
	var result = ResourceSaver.save(quest, path)

	if result == OK:
		print("✓ Updated quest: " + quest_id)
	else:
		push_error("✗ Failed to update quest: " + quest_id)

func update_quest_multi(
	quest_id: String,
	title: String,
	giver: String,
	description: String,
	dialogue: String,
	requirements_data: Array,  # Array of [species, min_str, min_agi, min_int]
	gold_reward: int,
	prerequisites: Array = []
) -> void:
	var requirements: Array[QuestRequirement] = []

	for req_data in requirements_data:
		var requirement = QuestRequirement.new()
		requirement.quantity = 1
		requirement.species_filter = req_data[0]
		requirement.min_strength = req_data[1]
		requirement.min_agility = req_data[2]
		requirement.min_intelligence = req_data[3]
		requirements.append(requirement)

	var reward = QuestReward.new()
	reward.gold = gold_reward

	var quest = QuestResource.new()
	quest.quest_id = quest_id
	quest.quest_title = title
	quest.quest_giver = giver
	quest.description = description
	quest.dialogue = dialogue
	quest.prerequisite_quest_ids.assign(prerequisites)
	quest.requirements.assign(requirements)
	quest.reward = reward

	var path = "res://resources/quests/" + quest_id + ".tres"
	var result = ResourceSaver.save(quest, path)

	if result == OK:
		print("✓ Updated quest: " + quest_id)
	else:
		push_error("✗ Failed to update quest: " + quest_id)

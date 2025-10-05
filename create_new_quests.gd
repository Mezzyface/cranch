@tool
extends EditorScript

# Run this script in Godot Editor: File -> Run
# Creates sample quests for the new creature species

func _run():
	print("Creating new quest resources...")

	# Quest 1: Tank creature needed
	create_quest(
		"GUARD-01",
		"Mechanical Guardian",
		"The Engineer",
		"I need a powerful mechanical guardian for my workshop.",
		"My workshop is under constant threat. I need a strong mechanical creature - a Guard Robot or Robo with exceptional strength!",
		GlobalEnums.Species.GUARD_ROBOT,
		500,  # Min strength
		0,
		0,
		500,  # Gold reward
		[]
	)

	# Quest 2: Speedster needed
	create_quest(
		"SPEED-01",
		"Lightning Fast",
		"The Racer",
		"Looking for the fastest creature around!",
		"I'm organizing a race and need creatures with incredible speed. Bring me a Neon Bat or Delinquent Chick with amazing agility!",
		GlobalEnums.Species.NEON_BAT,
		0,
		550,  # Min agility
		0,
		600,  # Gold reward
		[]
	)

	# Quest 3: Intelligent creature needed
	create_quest(
		"BRAIN-01",
		"The Trickster's Challenge",
		"The Puzzle Master",
		"Only the smartest creatures can solve my puzzles.",
		"I've created an impossible puzzle that requires exceptional intelligence. An Illusionary Raccoon or Stoplight Ghost should do nicely!",
		GlobalEnums.Species.ILLUSIONARY_RACCOON,
		0,
		0,
		550,  # Min intelligence
		700,  # Gold reward
		[]
	)

	# Quest 4: Beast needed
	create_quest(
		"BEAST-01",
		"Call of the Wild",
		"The Beast Tamer",
		"Seeking a powerful wild beast.",
		"I'm looking for a creature with raw, untamed power. A Grizzly with overwhelming strength would be perfect!",
		GlobalEnums.Species.GRIZZLY,
		700,  # Min strength
		0,
		0,
		800,  # Gold reward
		[]
	)

	# Quest 5: Balanced creature (sequel quest)
	create_quest(
		"BAL-01",
		"The Perfect Specimen",
		"The Collector",
		"I need a well-rounded creature.",
		"I'm looking for a creature with balanced abilities - not too specialized. Krip are known for their balance!",
		GlobalEnums.Species.KRIP,
		450,  # Min strength
		450,  # Min agility
		450,  # Min intelligence
		1000,  # Gold reward
		[]
	)

	# Quest 6: Hunter needed
	create_quest(
		"HUNT-01",
		"Spectral Hunter",
		"The Gravekeeper",
		"I need a hunting companion from the spirit realm.",
		"The graveyard needs protection. Bring me a Grave Robber's Hunting Dog with strong hunting instincts!",
		GlobalEnums.Species.GRAVE_ROBBER_HUNTING_DOG,
		500,  # Min strength
		550,  # Min agility
		0,
		650,  # Gold reward
		[]
	)

	# Quest 7: Elemental creature
	create_quest(
		"ELEM-01",
		"Fire and Stone",
		"The Alchemist",
		"Elemental creatures are needed for my experiments.",
		"I'm researching elemental properties. Bring me a Fire Pyrope with exceptional strength for my fire experiments!",
		GlobalEnums.Species.FIRE_PYROPE,
		600,  # Min strength
		0,
		0,
		700,  # Gold reward
		[]
	)

	# Quest 8: Any strong creature (no species filter)
	create_quest(
		"POWER-01",
		"Show of Strength",
		"The Arena Master",
		"Prove your creature's power!",
		"The arena demands power! Bring me ANY creature with strength of at least 700. Species doesn't matter - only raw power!",
		-1,  # Any species
		700,  # Min strength
		0,
		0,
		1200,  # Gold reward
		[]
	)

	print("Quest creation complete! Check resources/quests/ folder")

func create_quest(
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
	prerequisites: Array
) -> void:
	# Create requirement
	var requirement = QuestRequirement.new()
	requirement.quantity = 1
	requirement.species_filter = species
	requirement.min_strength = min_str
	requirement.min_agility = min_agi
	requirement.min_intelligence = min_int

	# Create reward
	var reward = QuestReward.new()
	reward.gold = gold_reward

	# Create quest
	var quest = QuestResource.new()
	quest.quest_id = quest_id
	quest.quest_title = title
	quest.quest_giver = giver
	quest.description = description
	quest.dialogue = dialogue
	quest.prerequisite_quest_ids.assign(prerequisites)
	quest.requirements.assign([requirement])
	quest.reward = reward

	# Save
	var path = "res://resources/quests/" + quest_id + ".tres"
	var result = ResourceSaver.save(quest, path)

	if result == OK:
		print("✓ Created quest: " + quest_id)
	else:
		push_error("✗ Failed to create quest: " + quest_id)

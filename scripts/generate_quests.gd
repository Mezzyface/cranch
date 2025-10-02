@tool
extends EditorScript

func _run():
	print("=== Generating Quest Resources ===")

	# Create quests directory if it doesn't exist
	var dir = DirAccess.open("res://resources/")
	if not dir.dir_exists("quests"):
		dir.make_dir("quests")

	# Generate all 5 quests
	generate_quest_col_01()
	generate_quest_col_02()
	generate_quest_col_03()
	generate_quest_col_04()
	generate_quest_col_05()

	print("=== Quest Generation Complete ===")
	print("Restart Godot to see the new quest files in FileSystem")

func generate_quest_col_01():
	var quest = QuestResource.new()
	quest.quest_id = "COL-01"
	quest.quest_title = "First Guardian"
	quest.quest_giver = "The Collector"
	quest.dialogue = "I need a strong guardian to protect my treasures. A Scuttleguard would be perfect—something with real strength!"
	quest.description = "The Collector needs a strong guardian."

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = GlobalEnums.Species.SCUTTLEGUARD
	req.min_strength = 15
	req.requirement_description = "Scuttleguard with STR ≥ 15"
	quest.requirements.append(req)

	var reward = QuestReward.new()
	reward.gold = 300
	quest.reward = reward

	var result = ResourceSaver.save(quest, "res://resources/quests/COL-01.tres")
	if result == OK:
		print("Created: COL-01.tres")
	else:
		print("Failed to create COL-01.tres")

func generate_quest_col_02():
	var quest = QuestResource.new()
	quest.quest_id = "COL-02"
	quest.quest_title = "Swift Scout"
	quest.quest_giver = "The Collector"
	quest.dialogue = "Excellent work! Now I need something fast to scout the perimeter. A Wind Dancer with great agility would be ideal."
	quest.description = "The Collector needs a swift scout."
	quest.prerequisite_quest_ids.append("COL-01")

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = GlobalEnums.Species.WIND_DANCER
	req.min_agility = 15
	req.requirement_description = "Wind Dancer with AGI ≥ 15"
	quest.requirements.append(req)

	var reward = QuestReward.new()
	reward.gold = 400
	quest.reward = reward

	var result = ResourceSaver.save(quest, "res://resources/quests/COL-02.tres")
	if result == OK:
		print("Created: COL-02.tres")
	else:
		print("Failed to create COL-02.tres")

func generate_quest_col_03():
	var quest = QuestResource.new()
	quest.quest_id = "COL-03"
	quest.quest_title = "Clever Companion"
	quest.quest_giver = "The Collector"
	quest.dialogue = "Impressive! Now I need a clever creature to help me catalog my collection. Intelligence is what matters here."
	quest.description = "The Collector needs an intelligent assistant."
	quest.prerequisite_quest_ids.append("COL-02")

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = -1  # Any species
	req.min_intelligence = 12
	req.requirement_description = "Any creature with INT ≥ 12"
	quest.requirements.append(req)

	var reward = QuestReward.new()
	reward.gold = 500
	quest.reward = reward

	var result = ResourceSaver.save(quest, "res://resources/quests/COL-03.tres")
	if result == OK:
		print("Created: COL-03.tres")
	else:
		print("Failed to create COL-03.tres")

func generate_quest_col_04():
	var quest = QuestResource.new()
	quest.quest_id = "COL-04"
	quest.quest_title = "Elite Squad"
	quest.quest_giver = "The Collector"
	quest.dialogue = "You've proven yourself! I'm expanding my operations and need an elite squad—two well-rounded creatures."
	quest.description = "The Collector needs two elite creatures."
	quest.prerequisite_quest_ids.append("COL-03")

	var req = QuestRequirement.new()
	req.quantity = 2
	req.species_filter = -1  # Any species
	req.min_strength = 12
	req.min_agility = 12
	req.min_intelligence = 12
	req.requirement_description = "Well-rounded creature (all stats ≥ 12)"
	quest.requirements.append(req)

	var reward = QuestReward.new()
	reward.gold = 800
	quest.reward = reward

	var result = ResourceSaver.save(quest, "res://resources/quests/COL-04.tres")
	if result == OK:
		print("Created: COL-04.tres")
	else:
		print("Failed to create COL-04.tres")

func generate_quest_col_05():
	var quest = QuestResource.new()
	quest.quest_id = "COL-05"
	quest.quest_title = "Ultimate Champion"
	quest.quest_giver = "The Collector"
	quest.dialogue = "This is it—the final test. I need a true champion, a creature with exceptional abilities across the board. Can you deliver?"
	quest.description = "The Collector seeks the ultimate champion."
	quest.prerequisite_quest_ids.append("COL-04")

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = -1  # Any species
	req.min_strength = 18
	req.min_agility = 18
	req.min_intelligence = 18
	req.requirement_description = "Champion (all stats ≥ 18)"
	quest.requirements.append(req)

	var reward = QuestReward.new()
	reward.gold = 2000
	reward.unlock_message = "Unlocked: Master Collector Title"
	quest.reward = reward

	var result = ResourceSaver.save(quest, "res://resources/quests/COL-05.tres")
	if result == OK:
		print("Created: COL-05.tres")
	else:
		print("Failed to create COL-05.tres")

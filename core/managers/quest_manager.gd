# core/managers/quest_manager.gd
extends Node
class_name QuestManager

# All quests available in the game (loaded from resources)
var all_quests: Dictionary = {}  # [quest_id: String] -> QuestResource

# Quest progress tracking
var active_quests: Array[String] = []  # Quest IDs currently active
var completed_quests: Array[String] = []  # Quest IDs already completed

# Currently selected quest for turn-in UI
var current_quest_for_turnin: QuestResource = null

func initialize():
	"""Called by GameManager on game start"""
	print("QuestManager: initialize() called")
	load_all_quests()

	print("QuestManager: Total quests loaded: ", all_quests.size())

	# Auto-accept first quest in chain (only if no quests active/completed)
	if active_quests.is_empty() and completed_quests.is_empty():
		if all_quests.has("COL-01"):
			print("QuestManager: Auto-accepting COL-01")
			accept_quest("COL-01")
		else:
			print("QuestManager: COL-01 not found in all_quests")

# Load quest resources from disk
func load_all_quests():
	all_quests.clear()

	# Load all .tres quest files from resources/quests/ folder
	var quest_dir = "res://resources/quests/"
	var dir = DirAccess.open(quest_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var quest_path = quest_dir + file_name
				var quest = load(quest_path) as QuestResource
				if quest:
					register_quest(quest)
					print("Loaded quest: ", quest.quest_title, " (", quest.quest_id, ")")
				else:
					print("Failed to load quest: ", quest_path)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		print("Failed to open quest directory: ", quest_dir)

func register_quest(quest: QuestResource):
	all_quests[quest.quest_id] = quest

# Accept a quest
func accept_quest(quest_id: String) -> bool:
	if not all_quests.has(quest_id):
		print("Quest not found: ", quest_id)
		return false

	if quest_id in active_quests or quest_id in completed_quests:
		print("Quest already active or completed: ", quest_id)
		return false

	var quest = all_quests[quest_id]

	# Check prerequisites
	if not quest.prerequisites_met(completed_quests):
		print("Prerequisites not met for quest: ", quest_id)
		return false

	active_quests.append(quest_id)
	SignalBus.quest_accepted.emit(quest)
	print("Quest accepted: ", quest.quest_title)
	return true

# Validate if player can complete quest with selected creatures
func can_complete_quest(quest_id: String, creatures: Array[CreatureData]) -> Dictionary:
	if not all_quests.has(quest_id):
		return {"valid": false, "missing": ["Quest not found"]}

	var quest = all_quests[quest_id]
	return quest.validate_creatures(creatures)

# Complete a quest and give rewards
func complete_quest(quest_id: String, creatures: Array[CreatureData]) -> bool:
	if not quest_id in active_quests:
		print("Quest not active: ", quest_id)
		return false

	var quest = all_quests[quest_id]
	var validation = quest.validate_creatures(creatures)

	if not validation.valid:
		print("Creatures don't meet requirements: ", validation.missing)
		SignalBus.quest_turn_in_failed.emit(quest, validation.missing)
		return false

	# Remove from active, add to completed
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)

	# Give rewards
	if quest.reward:
		if quest.reward.gold > 0:
			SignalBus.gold_change_requested.emit(quest.reward.gold)
		# Future: Give XP, items, etc.

	# Remove creatures from player's collection (they've been turned in)
	for creature in creatures:
		GameManager.remove_creature(creature)

	SignalBus.quest_completed.emit(quest)
	print("Quest completed: ", quest.quest_title)

	# Check for next quest in chain
	check_unlock_next_quests()

	return true

# Check if completing a quest unlocks the next one
func check_unlock_next_quests():
	for quest_id in all_quests.keys():
		if quest_id in active_quests or quest_id in completed_quests:
			continue

		var quest = all_quests[quest_id]
		if quest.prerequisites_met(completed_quests):
			accept_quest(quest_id)

# Get all available quests (not completed)
func get_available_quests() -> Array[QuestResource]:
	var available: Array[QuestResource] = []
	for quest_id in active_quests:
		if all_quests.has(quest_id):
			available.append(all_quests[quest_id])
	return available

# Get all completed quests
func get_completed_quests() -> Array[QuestResource]:
	var completed: Array[QuestResource] = []
	for quest_id in completed_quests:
		if all_quests.has(quest_id):
			completed.append(all_quests[quest_id])
	return completed

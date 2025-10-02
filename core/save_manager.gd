# SaveManager - Handles all save/load operations
extends Node

const SAVE_PATH = "user://savegame.tres"

func save_game() -> bool:
	var save_data = SaveGame.new()
	save_data.gold = GameManager.player_data.gold
	save_data.current_week = GameManager.current_week
	save_data.creatures = GameManager.player_data.creatures.duplicate()
	save_data.active_quest_ids = GameManager.quest_manager.active_quests.duplicate()
	save_data.completed_quest_ids = GameManager.quest_manager.completed_quests.duplicate()
	save_data.save_date = Time.get_datetime_string_from_system()

	var result = ResourceSaver.save(save_data, SAVE_PATH)
	if result == OK:
		print("Game saved successfully")
		SignalBus.game_saved.emit()
	else:
		print("Failed to save game")
		SignalBus.save_failed.emit()
	return result == OK

func load_game() -> bool:
	if not ResourceLoader.exists(SAVE_PATH):
		print("No save file found")
		return false

	var save_data = ResourceLoader.load(SAVE_PATH) as SaveGame
	if not save_data:
		print("Failed to load save file")
		return false

	# Restore game state to GameManager
	GameManager.current_week = save_data.current_week

	# Restore player data
	GameManager.player_data = PlayerData.new()
	GameManager.player_data.gold = save_data.gold
	GameManager.player_data.creatures = save_data.creatures.duplicate()

	# Restore quest progress
	GameManager.quest_manager.active_quests = save_data.active_quest_ids.duplicate()
	GameManager.quest_manager.completed_quests = save_data.completed_quest_ids.duplicate()

	print("Game loaded from: ", save_data.save_date)
	SignalBus.game_loaded.emit()
	return true

func has_save_file() -> bool:
	return ResourceLoader.exists(SAVE_PATH)

func delete_save() -> bool:
	if has_save_file():
		var result = DirAccess.remove_absolute(SAVE_PATH.replace("user://", OS.get_user_data_dir() + "/"))
		return result == OK
	return false

func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}

	var save_data = ResourceLoader.load(SAVE_PATH) as SaveGame
	if save_data:
		return {
			"date": save_data.save_date,
			"week": save_data.current_week,
			"gold": save_data.gold,
			"creature_count": save_data.creatures.size()
		}
	return {}

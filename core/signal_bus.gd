# SignalBus - Central hub for all game signals
extends Node

# Game Flow Signals
signal game_started()
signal player_data_initialized()
signal week_advanced(week: int)

# Save/Load Signals
signal game_saved()
signal game_loaded()
signal save_failed()

# Player & Resource Signals
signal gold_changed(new_amount: int)
signal creature_added(creature: CreatureData)
signal creature_stats_changed(creature: CreatureData)

# UI Signals
signal show_debug_popup_requested()
signal show_creature_details_requested(creature: CreatureData)
signal popup_closed(popup_name: String)

# Activity & Training Signals
signal training_started(creature: CreatureData, facility: Resource)
signal training_completed(creature: CreatureData)
signal activity_completed(creature: CreatureData, activity: Resource)

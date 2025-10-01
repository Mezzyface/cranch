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

# UI Events
signal show_debug_popup_requested
signal show_creature_details_requested(creature)
signal creature_clicked(creature_data: CreatureData)  # NEW: Emitted when creature is clicked
signal popup_closed(popup_name)

# Activity & Facility signals
signal activity_started(creature: CreatureData, activity: ActivityResource)
signal activity_completed(creature: CreatureData, activity: ActivityResource)
signal creature_species_changed(creature: CreatureData)
signal facility_assigned(creature: CreatureData, facility: FacilityResource)
signal facility_unassigned(creature: CreatureData, facility: FacilityResource)
signal facility_slot_unlocked(slot_index: int, cost: int)

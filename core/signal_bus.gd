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
signal creature_removed(creature: CreatureData)
signal creature_stats_changed(creature: CreatureData)
signal creature_tag_added(creature: CreatureData, tag_id: String)
signal creature_tag_removed(creature: CreatureData, tag_id: String)

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

# Shop & Commerce
signal shop_opened(shop: ShopResource)
signal shop_closed()
signal shop_selector_opened()
signal shop_selector_closed()
signal shop_purchase_completed(item_name: String, cost: int)
signal shop_purchase_failed(reason: String)

# Gold Management
signal gold_change_requested(amount: int)  # Request to add/remove gold (negative = spend)

# Quest System
signal quest_accepted(quest: QuestResource)
signal quest_completed(quest: QuestResource)
signal quest_turn_in_failed(quest: QuestResource, missing_requirements: Array)
signal quest_turn_in_started(quest: QuestResource)
signal quest_log_opened()
signal quest_log_closed()

# Inventory System
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal inventory_updated()

# Food Assignment
signal creature_food_assigned(creature: CreatureData, item_id: String)
signal creature_food_unassigned(creature: CreatureData)
signal food_selection_requested(creature: CreatureData)  # Opens food picker UI

# Week Advancement
signal week_advancement_blocked(reason: String, creatures: Array)  # Prevents week progress

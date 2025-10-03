# Development Guide - Living Document

## How We Work Together

### Our Development Process
When implementing features, we follow this pattern:
1. **You request a feature/change**
2. **I provide implementation steps in this document**
3. **You follow along and implement**
4. **We update the architecture documentation as we go**

This document serves as:
- A living reference of your game's architecture
- A place for step-by-step implementation guides
- Documentation of signal flow and connections

---

## Current Game Architecture

### Signal Flow Map

```
[Main Menu] --click start--> [Game Scene] --emits--> game_started
                                   |
                                   v
                            [SignalBus]
                                   |
                    +--------------+-------------+
                    |                            |
                    v                            v
            [GameManager]                 [UI Components]
            initialize_new_game()         (Debug Popup, HUD, etc)
                    |
                    v
            Creates PlayerData
            Creates Starter Creature
                    |
                    v
            Emits: player_data_initialized
                   creature_added
                   gold_changed
```

### Active Signal Connections

#### SignalBus Signals
```gdscript
# Game Flow
game_started → GameManager.initialize_new_game()
player_data_initialized → game_scene._on_player_data_ready()

# Save/Load
game_saved → [Not connected yet]
game_loaded → [Not connected yet]
save_failed → [Not connected yet]

# Player & Resources
gold_change_requested(amount) → GameManager._on_gold_change_requested()
gold_changed(amount) → UI components (for display updates)
creature_added(creature) → game_scene._on_creature_added()
creature_stats_changed(creature) → [Not connected yet]

# Game Progress
week_advanced(week) → FacilityManager.process_all_activities()

# Activity & Facility
activity_started(creature, activity) → [Not connected yet]
activity_completed(creature, activity) → [Not connected yet]
creature_species_changed(creature) → [Not connected yet]
facility_assigned(creature, facility) → FacilityManager.register_assignment()
facility_unassigned(creature, facility) → FacilityManager.unregister_assignment()

# UI Events
show_debug_popup_requested → [Not connected yet]
show_creature_details_requested(creature) → [Not connected yet]
creature_clicked(creature_data) → game_scene._on_creature_clicked()
popup_closed(popup_name) → [Not connected yet]

# Shop & Commerce
shop_opened(shop) → ShopWindow displays shop
shop_closed() → ShopWindow closes/hides
shop_purchase_completed(item_name, cost) → ShopWindow.refresh_items()
shop_purchase_failed(reason) → ShopWindow shows error (console for now)

# Quest System
quest_accepted(quest) → QuestWindow.refresh_quest_list()
quest_completed(quest) → QuestWindow.refresh_quest_list() + completion popup
quest_turn_in_failed(quest, missing) → Show error message
quest_turn_in_started(quest) → game_scene._on_quest_turn_in_started()
quest_log_opened() → [Not connected yet]
quest_log_closed() → [Not connected yet]
creature_removed(creature) → game_scene._on_creature_removed() (visual cleanup)
```

### System Overview

#### Autoload Order (Important!)
1. `GlobalEnums` - Game enumerations and constants (Species, CreatureState, FacingDirection, Emote, ItemType)
2. `SignalBus` - Central signal hub
3. `GameManager` - Game state management
4. `SaveManager` - Save/load operations

#### Core Systems

**GameManager**
- Manages PlayerData (gold, creatures)
- Handles game initialization
- Controls week progression
- Listens for `gold_change_requested` signal and updates player gold
- Emits state changes through SignalBus
- Contains `facility_manager` instance (FacilityManager)
- Contains `quest_manager` instance (QuestManager)

**FacilityManager** (accessed via `GameManager.facility_manager`)
- Tracks creature-to-facility assignments
- Processes all activities on week advancement
- Handles registration/unregistration of creatures
- Dictionary: `{facility: [creatures]}`
- Created and managed by GameManager

**QuestManager** (accessed via `GameManager.quest_manager`)
- Manages quest progression and completion
- Loads quest resources from resources/quests/ folder
- Tracks active and completed quest IDs
- Validates creature requirements for turn-ins
- Auto-accepts next quests in chain when prerequisites met
- Handles reward distribution
- Created and managed by GameManager (not autoload)

**SignalBus**
- Central hub for all signals
- No logic, just signal definitions
- Enables decoupled communication

**SaveManager**
- Handles all game persistence
- Resource-based saves at `user://savegame.tres`
- F5 to save, F9 to load
- Save metadata and versioning

**PlayerData Resource**
- Contains: gold, creatures array
- Persistent data structure

**CreatureData Resource**
- Contains: name, species, strength, agility, intelligence
- Individual creature stats

**DragDropComponent**
- Unified component for all drag/drop interactions
- Supports multiple drag types (CREATURE, FACILITY_CARD, CUSTOM)
- Configurable flags: `can_drag`, `can_accept_drops`
- Custom validation via callbacks
- Visual preview generation
- Signal-based communication (`drag_started`, `drag_ended`, `drop_received`)

**CreatureGenerator** (`scripts/creature_generation.gd`)
- Static utility class for procedural creature generation
- Species-based stat curves with normal distribution
- Random name generation per species

**ShopManager** (`scripts/shop_manager.gd`) - if implemented
- Static utility class for shop purchases
- Handles validation, gold transactions, SignalBus integration
- Not an autoload - called directly by UI components

---

## Implementation Steps Section

**Current Status**: All planned features implemented and working! Ready for next feature.

---

## Completed Implementation History

### ✅ Food/Inventory System (Completed 2025-01-03)

**What Was Implemented:**
- Complete item/inventory system with ItemResource and InventoryManager
- Food requirement: creatures must have food assigned before week advancement
- Food assignment UI: clickable buttons below facility cards
- Food selector popup: shows available food from inventory
- Food consumption: removes food when training executes
- Save/load persistence for inventory
- Shop integration for purchasing food items

**Key Architecture Decisions:**
1. **Food buttons rendered outside card hierarchy**: To avoid z-index/mouse-filter conflicts with drag components
2. **InventoryManager as instance (not autoload)**: Initialized in GameManager with player_data reference
3. **Dynamic food button positioning**: Uses `_process()` to follow facility cards
4. **Same-facility drag optimization**: Calls `update_slots()` instead of add/remove to prevent sprite disappearance

**Bug Fixes During Implementation:**
- Fixed food buttons blocked by drag components → moved outside card hierarchy
- Fixed sprite disappearing when dragging between slots → detect same-facility and use update_slots()
- Fixed button visibility → use `show()` instead of `visible = true`

**Files Created:**
- `core/managers/inventory_manager.gd` (98 lines)
- `scenes/windows/food_selector.gd` + `.tscn`
- `resources/items/food_basic.tres` and `food_premium.tres`

**Signals Added:**
- `item_added`, `item_removed`, `inventory_updated`
- `creature_food_assigned`, `creature_food_unassigned`
- `food_selection_requested`
- `week_advancement_blocked`

---

### 🐛 Bug Fix: Food Slot Not Appearing After Creature Assignment

**Issue**: When dropping a creature into a facility slot, the food slot button remains invisible.

**Root Cause**: The `assign_creature()` and `assign_creature_from_drag()` functions call `_add_creature_sprite()` directly, which doesn't update the food button visibility. Food buttons are only shown/hidden in `update_slots()`.

**File**: `scenes/card/facility_card.gd`

**Fix 1 - In `assign_creature()` function** (around line 121):

**Current code** (lines 125-126):
```gdscript
		# Add the creature sprite to the card
		_add_creature_sprite(creature, assigned_creatures.size() - 1)
```

**Replace with**:
```gdscript
		# Update all slots to show creature and food button
		update_slots()
```

**Fix 2 - In `assign_creature_from_drag()` function** (around line 142):

**Current code** (lines 147-148):
```gdscript
		# Add the creature sprite to the card
		_add_creature_sprite(creature, assigned_creatures.size() - 1)
```

**Replace with**:
```gdscript
		# Update all slots to show creature and food button
		update_slots()
```

**Why**: `update_slots()` is the single source of truth for slot display. It handles:
- Creating creature sprites via `_add_creature_sprite()`
- Showing/hiding food buttons based on slot occupancy
- Setting food button text and color based on assignment status
- Connecting food button signals

By calling `update_slots()` instead of `_add_creature_sprite()` directly, we ensure food buttons appear correctly when creatures are assigned.

**Additional Fix - Sprite Positioning Issue**

**Issue**: After the above fix, the creature sprite appears on top of the food button instead of above it.

**Root Cause**: The `VBoxContainer` slot structure has children in order: Label → FoodButton → Background. When the sprite is added via `add_child()`, it becomes the last child, appearing below the food button in the vertical layout.

**File**: `scenes/card/facility_card.gd`

**Fix in `_add_creature_sprite()` function** (around line 200):

**Current code**:
```gdscript
	# Position the sprite in the slot container
	var slot_container = creature_slots.get_child(slot_index)
	slot_container.add_child(sprite)
	sprite.position = Vector2(30, 30)  # Center in the 60x60 slot
```

**Replace with**:
```gdscript
	# Position the sprite in the slot container
	var slot_container = creature_slots.get_child(slot_index)

	# Find the food button index to insert sprite before it
	var food_button_index = -1
	for i in range(slot_container.get_child_count()):
		if slot_container.get_child(i).name == "FoodSlotButton":
			food_button_index = i
			break

	# Add sprite at the correct position (before food button if found)
	if food_button_index >= 0:
		slot_container.add_child(sprite)
		slot_container.move_child(sprite, food_button_index)
	else:
		slot_container.add_child(sprite)

	sprite.position = Vector2(30, 30)  # Center in the 60x60 slot
```

**Why**: In a `VBoxContainer`, child order determines vertical layout. By finding the food button's index and using `move_child()` to reorder the sprite before it, the layout becomes: Label → Sprite → FoodButton → Background. This ensures the food button appears below the creature sprite.

**Third Fix - Food Button Not Clickable & Invisible**

**Issue**: After the above fixes, the food button cannot be clicked and remains invisible even though visibility is set to true.

**Root Cause 1**: The drag component covers the entire slot (60x80) including the food button area, blocking mouse input to the button.

**Root Cause 2**: Using `visible = true` doesn't work reliably in Godot when the button was initially hidden. Need to use `show()` instead.

**File**: `scenes/card/facility_card.gd`

**Fix 1 - In `_add_creature_sprite()` function** (around line 233):

**Current code**:
```gdscript
	drag_component.size = slot_container.size
```

**Replace with**:
```gdscript
	drag_component.size = Vector2(60, 60)  # Only cover sprite area, not food button below
```

**Fix 2 - In `update_slots()` function** (around line 288):

**Current code**:
```gdscript
	food_button.visible = true
```

**Replace with**:
```gdscript
	food_button.show()  # Use show() instead of visible = true
```

**Why**:
1. The slot is 60x80 (width x height) with the sprite occupying the top 60x60 area and the food button in the bottom 20px. By limiting the drag component to 60x60, it only covers the sprite area, allowing the food button below to receive mouse clicks.
2. In Godot, `show()` properly makes a hidden node visible and processes all visibility inheritance, while `visible = true` can fail when nodes have complex visibility states. Always use `show()`/`hide()` for runtime visibility changes.

---

### 🔨 Item System with Food Requirements for Training Facilities

**Goal**: Implement an item/inventory system where each creature in a facility has a food slot. Players click the slot to select food from inventory. Week progression is blocked until all creatures have food assigned. Food is consumed when training runs.

**Design Philosophy**:
- Each creature slot in a facility has a food slot
- Click food slot → Opens food selection UI from inventory
- Assigned food stored per-creature in FacilityManager
- Week advancement validates all creatures have food
- Future: Different foods provide stat boost multipliers

---

#### Step 1: Add ItemType enum to GlobalEnums

**File**: `core/global_enums.gd`

**At the end of the file, add**:
```gdscript
enum ItemType {
	FOOD,
	EQUIPMENT,
	CONSUMABLE,
	MATERIAL,
	SPECIAL
}
```

**Why**: We need a way to categorize items. Food items will be consumed during training, while other types (equipment, consumables) can be used for future systems.

---

#### Step 2: Update ItemResource with type and consumable properties

**File**: `resources/item_resource.gd`

**Current structure** (lines 1-9):
```gdscript
extends Resource
class_name ItemResource

@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon_path: String = ""
@export var is_stackable: bool = true
@export var max_stack_size: int = 99
```

**Add after line 9**:
```gdscript
@export var item_type: GlobalEnums.ItemType = GlobalEnums.ItemType.MATERIAL
@export var stat_boost_multiplier: float = 1.0  # Training boost (1.0 = normal, 1.5 = 50% bonus, etc.)
```

**Why**: We need to distinguish food items from other items. `stat_boost_multiplier` enables future feature where premium foods provide training bonuses (e.g., premium food = 1.5x stats gained). For now, all foods use 1.0 (normal training).

---

#### Step 3: Add inventory to PlayerData

**File**: `resources/player_data.gd`

**Current exports** (lines 4-5):
```gdscript
@export var gold: int = 0
@export var creatures: Array[CreatureData] = []
```

**Add after line 5**:
```gdscript
@export var inventory: Dictionary = {}  # {item_id: quantity}
```

**Why**: Player needs persistent storage for items. Using Dictionary with item_id keys allows efficient lookups and stacking. Format: `{"food_basic": 10, "food_premium": 3}`.

---

#### Step 4: Create InventoryManager class

**Create new file**: `core/managers/inventory_manager.gd`

```gdscript
class_name InventoryManager

# Reference to player data
var player_data: PlayerData

# Item database - loaded from resources/items/
var _item_database: Dictionary = {}  # {item_id: ItemResource}

func _init(p_player_data: PlayerData):
	player_data = p_player_data
	_load_item_database()

# Load all item resources from resources/items/ folder
func _load_item_database():
	var items_path = "res://resources/items/"
	var dir = DirAccess.open(items_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var item_path = items_path + file_name
				var item: ItemResource = load(item_path)
				if item:
					var item_id = file_name.replace(".tres", "")
					_item_database[item_id] = item
					print("Loaded item: ", item_id)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Failed to open items directory: " + items_path)

# Add item to inventory
func add_item(item_id: String, quantity: int = 1) -> bool:
	if not _item_database.has(item_id):
		push_error("Item not found in database: " + item_id)
		return false

	var item: ItemResource = _item_database[item_id]

	if not item.is_stackable and player_data.inventory.has(item_id):
		push_error("Cannot add non-stackable item that already exists")
		return false

	# Add to inventory
	if player_data.inventory.has(item_id):
		var new_quantity = player_data.inventory[item_id] + quantity
		if item.is_stackable and new_quantity > item.max_stack_size:
			push_error("Cannot exceed max stack size")
			return false
		player_data.inventory[item_id] = new_quantity
	else:
		player_data.inventory[item_id] = quantity

	SignalBus.item_added.emit(item_id, quantity)
	return true

# Remove item from inventory
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not player_data.inventory.has(item_id):
		return false

	if player_data.inventory[item_id] < quantity:
		return false

	player_data.inventory[item_id] -= quantity

	# Remove from dict if quantity reaches 0
	if player_data.inventory[item_id] <= 0:
		player_data.inventory.erase(item_id)

	SignalBus.item_removed.emit(item_id, quantity)
	return true

# Check if player has enough of an item
func has_item(item_id: String, quantity: int = 1) -> bool:
	return player_data.inventory.get(item_id, 0) >= quantity

# Get item quantity
func get_item_quantity(item_id: String) -> int:
	return player_data.inventory.get(item_id, 0)

# Get item resource from database
func get_item_resource(item_id: String) -> ItemResource:
	return _item_database.get(item_id)

# Get all items of a specific type
func get_items_by_type(item_type: GlobalEnums.ItemType) -> Array[String]:
	var result: Array[String] = []
	for item_id in _item_database.keys():
		var item: ItemResource = _item_database[item_id]
		if item.item_type == item_type:
			result.append(item_id)
	return result
```

**Why**:
- Centralizes all inventory operations
- Loads item database automatically on initialization
- Validates stack limits and item existence
- Emits signals for UI updates
- Provides helper functions for checking/getting items
- Separates inventory logic from GameManager
- Instance-based (not autoload) - follows FacilityManager/QuestManager pattern

---

#### Step 5: Add inventory signals to SignalBus

**File**: `core/signal_bus.gd`

**In the appropriate section, add**:
```gdscript
# Inventory System
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal inventory_updated()

# Training System
signal training_failed_insufficient_food(facility: FacilityResource, creature: CreatureData)
```

**Why**:
- `item_added/removed` - UI can react to inventory changes
- `inventory_updated` - Broad signal for full inventory refreshes
- `training_failed_insufficient_food` - Notify player when training can't happen

---

#### Step 6: Update FacilityManager to track food assignments

**File**: `core/managers/facility_manager.gd`

**Add new data structure** (after `_creature_assignments` declaration):
```gdscript
# Track food assigned to each creature in facilities
# Format: {creature: item_id} or {creature: null} if no food assigned
var _creature_food_assignments: Dictionary = {}
```

**Add new functions**:
```gdscript
# Assign food to a creature in a facility
func assign_food_to_creature(creature: CreatureData, item_id: String):
	_creature_food_assignments[creature] = item_id
	SignalBus.creature_food_assigned.emit(creature, item_id)
	print("Assigned food '%s' to creature '%s'" % [item_id, creature.name])

# Remove food assignment from creature
func unassign_food_from_creature(creature: CreatureData):
	if _creature_food_assignments.has(creature):
		_creature_food_assignments.erase(creature)
		SignalBus.creature_food_unassigned.emit(creature)

# Check if creature has food assigned
func has_food_assigned(creature: CreatureData) -> bool:
	return _creature_food_assignments.has(creature) and _creature_food_assignments[creature] != null

# Get food assigned to creature
func get_assigned_food(creature: CreatureData) -> String:
	return _creature_food_assignments.get(creature, "")

# Check if all creatures in facilities have food assigned
func all_creatures_have_food() -> bool:
	for facility in _creature_assignments.keys():
		var creatures = _creature_assignments[facility]
		for creature in creatures:
			if not has_food_assigned(creature):
				return false
	return true

# Get list of creatures missing food
func get_creatures_missing_food() -> Array[CreatureData]:
	var missing: Array[CreatureData] = []
	for facility in _creature_assignments.keys():
		var creatures = _creature_assignments[facility]
		for creature in creatures:
			if not has_food_assigned(creature):
				missing.append(creature)
	return missing
```

**Update `unregister_creature()` function** to clean up food assignments:
```gdscript
func unregister_creature(creature: CreatureData, facility: FacilityResource):
	if _creature_assignments.has(facility):
		_creature_assignments[facility].erase(creature)

		# Clean up empty facility entries
		if _creature_assignments[facility].is_empty():
			_creature_assignments.erase(facility)

		# Clean up food assignment
		unassign_food_from_creature(creature)  # Add this line

		SignalBus.facility_unassigned.emit(creature, facility)
```

**Why**: FacilityManager needs to track which food is assigned to each creature. This allows validation before week advancement and provides data for UI display. Food assignments are cleaned up when creatures are removed from facilities.

---

#### Step 7: Update FacilityManager to consume assigned food

**File**: `core/managers/facility_manager.gd`

**Find the `process_all_activities()` function** (around line 40):

**Current code**:
```gdscript
func process_all_activities():
	for facility in _creature_assignments.keys():
		var creatures = _creature_assignments[facility]

		for creature in creatures:
			for activity in facility.activities:
				activity.run_activity(creature)
				SignalBus.activity_completed.emit(creature, activity)
```

**Replace with**:
```gdscript
func process_all_activities():
	# This should only be called after validation ensures all creatures have food
	for facility in _creature_assignments.keys():
		var creatures = _creature_assignments[facility]

		for creature in creatures:
			# Get and consume assigned food
			var food_item_id = get_assigned_food(creature)
			if food_item_id.is_empty():
				push_error("Creature %s has no food assigned - this should be prevented!" % creature.name)
				continue

			# Remove food from inventory
			if not GameManager.inventory_manager.remove_item(food_item_id, 1):
				push_error("Failed to remove food %s from inventory" % food_item_id)
				continue

			# Get stat boost multiplier from food (for future enhancement)
			var food_resource = GameManager.inventory_manager.get_item_resource(food_item_id)
			var stat_multiplier = 1.0
			if food_resource:
				stat_multiplier = food_resource.stat_boost_multiplier

			# Process activities (in future, pass stat_multiplier to activities)
			for activity in facility.activities:
				activity.run_activity(creature)
				SignalBus.activity_completed.emit(creature, activity)

			# Clear food assignment after consumption
			unassign_food_from_creature(creature)
```

**Why**:
- Consumes the specific food assigned to each creature
- Validates food assignment (defensive programming)
- Removes food from inventory one at a time per creature
- Retrieves stat_multiplier from food (ready for future boost system)
- Clears food assignment after use (forces player to reassign for next week)
- Only runs after validation ensures all creatures have food

---

#### Step 8: Create InventoryManager instance in GameManager

**File**: `core/game_manager.gd`

**After the `facility_manager` and `quest_manager` declarations** (around line 10):
```gdscript
var inventory_manager: InventoryManager
```

**In `initialize_new_game()` function, after creating player_data**:
```gdscript
# Initialize inventory manager
inventory_manager = InventoryManager.new(player_data)
```

**In the signal connection for `game_loaded`** (if it exists):
```gdscript
# Reinitialize inventory manager after load
inventory_manager = InventoryManager.new(player_data)
```

**Why**: GameManager creates and owns the InventoryManager instance. It's initialized with player_data during game start and must be recreated after loading a save to ensure proper references. Follows the same pattern as FacilityManager and QuestManager.

---

#### Step 9: Add week advancement validation in GameManager

**File**: `core/game_manager.gd`

**Find `advance_week()` function** (the one called when player clicks to progress):

**Add validation at the beginning**:
```gdscript
func advance_week():
	# Check if all creatures have food assigned
	if not facility_manager.all_creatures_have_food():
		var missing = facility_manager.get_creatures_missing_food()
		SignalBus.week_advancement_blocked.emit("Some creatures need food!", missing)
		print("Cannot advance week: %d creatures need food" % missing.size())
		return

	# Existing week advancement code...
	current_week += 1
	SignalBus.week_advanced.emit(current_week)
```

**Why**: Prevents week advancement until all creatures in facilities have food assigned. Emits signal with list of creatures missing food so UI can show helpful feedback. This enforces the requirement that players must assign food before progressing.

---

#### Step 10: Update SaveManager to include inventory

**File**: `core/save_manager.gd`

**Find `save_game()` function**, locate where PlayerData is saved:

**Add after copying creatures array**:
```gdscript
# Save inventory
save_data.inventory = GameManager.player_data.inventory.duplicate(true)
```

**Find `load_game()` function**, locate where PlayerData is restored:

**Add after restoring creatures**:
```gdscript
# Restore inventory
GameManager.player_data.inventory = save_data.inventory.duplicate(true)
SignalBus.inventory_updated.emit()
```

**Why**: Inventory needs to persist across save/load. We duplicate to avoid reference issues.

---

#### Step 11: Update SaveGame resource to store inventory

**File**: `resources/save_game.gd`

**Add export property**:
```gdscript
@export var inventory: Dictionary = {}
```

**Why**: SaveGame resource needs to serialize the inventory dictionary.

---

#### Step 12: Create basic food item resources

**Create folder**: `resources/items/` (if it doesn't exist)

**Create file**: `resources/items/food_basic.tres`

**In Godot Editor**:
1. Create new ItemResource
2. Set properties:
   - `item_name`: "Basic Food"
   - `description`: "Simple creature food. One meal for one training session."
   - `item_type`: FOOD
   - `stat_boost_multiplier`: 1.0
   - `is_stackable`: true
   - `max_stack_size`: 99
3. Save as `food_basic.tres`

**Create file**: `resources/items/food_premium.tres`

**In Godot Editor**:
1. Create new ItemResource
2. Set properties:
   - `item_name`: "Premium Food"
   - `description`: "High-quality creature food. Provides +50% training bonus!"
   - `item_type`: FOOD
   - `stat_boost_multiplier`: 1.5
   - `is_stackable`: true
   - `max_stack_size`: 99
3. Save as `food_premium.tres`

**Why**: We need actual item resources for the system to work. Basic food for standard training (1.0x stats), premium food provides 50% bonus (1.5x stats) - future feature ready.

---


#### Step 13: Update SignalBus with new signals

**File**: `core/signal_bus.gd`

**Add to inventory section**:
```gdscript
# Food Assignment
signal creature_food_assigned(creature: CreatureData, item_id: String)
signal creature_food_unassigned(creature: CreatureData)
signal food_selection_requested(creature: CreatureData)  # Opens food picker UI

# Week Advancement
signal week_advancement_blocked(reason: String, creatures: Array)  # Prevents week progress
```

**Why**: New signals for food assignment flow. `food_selection_requested` will open UI to pick food from inventory. `week_advancement_blocked` alerts player when they can't progress the week.

---

#### Step 14: Give player starter food in GameManager

**File**: `core/game_manager.gd`

**Find `initialize_new_game()` function**, after creature generation:

**Add**:
```gdscript
# Give starter food
inventory_manager.add_item("food_basic", 20)
```

**Why**: Players need food to start training. 20 basic food = 20 creature-weeks of training, enough to get started.

---

#### Step 15: Add food slot UI to FacilityCard

**File**: `scenes/card/facility_card.tscn`

**For each creature slot in the UI, add a food slot button**:
```
CreatureSlot_0
├── CreatureSprite (existing)
└── FoodSlotButton (new Button node)
    ├── Position: Below creature sprite
    ├── Size: 40x40
    ├── Text: "🍖" or "+" (when no food assigned)
```

**File**: `scenes/card/facility_card.gd`

**Add @onready references for food slot buttons**:
```gdscript
@onready var food_slot_buttons = [
	$CreatureSlot_0/FoodSlotButton,
	$CreatureSlot_1/FoodSlotButton,
	$CreatureSlot_2/FoodSlotButton
]
```

**In `update_slots()` function, after creating creature sprites**:
```gdscript
# Update food slot buttons
for i in range(food_slot_buttons.size()):
	var food_button = food_slot_buttons[i]

	if i < assigned_creatures.size():
		var creature = assigned_creatures[i]
		food_button.visible = true

		# Check if creature has food assigned
		var assigned_food = GameManager.facility_manager.get_assigned_food(creature)
		if assigned_food.is_empty():
			food_button.text = "+"
			food_button.modulate = Color.RED  # Visual cue that food is needed
		else:
			var food_item = GameManager.inventory_manager.get_item_resource(assigned_food)
			if food_item:
				food_button.text = "🍖"  # Or use food_item.icon_path
				food_button.modulate = Color.WHITE

		# Connect button press
		if not food_button.pressed.is_connected(_on_food_slot_pressed):
			food_button.pressed.connect(_on_food_slot_pressed.bind(creature))
	else:
		food_button.visible = false
```

**Add handler function**:
```gdscript
func _on_food_slot_pressed(creature: CreatureData):
	SignalBus.food_selection_requested.emit(creature)
```

**Connect to food assignment signals in `_ready()`**:
```gdscript
SignalBus.creature_food_assigned.connect(_on_food_assigned)
SignalBus.creature_food_unassigned.connect(_on_food_unassigned)

func _on_food_assigned(creature: CreatureData, item_id: String):
	update_slots()  # Refresh display

func _on_food_unassigned(creature: CreatureData):
	update_slots()  # Refresh display
```

**Why**: Each creature slot now has a clickable food slot. Shows "+" when empty (red tint for urgency), shows food icon when assigned. Clicking opens food selection UI. Updates automatically via signals.

---

#### Step 16: Create food selection popup UI

**Create file**: `scenes/windows/food_selector.tscn`

**Scene structure**:
```
Panel (FoodSelector)
├── VBoxContainer
│   ├── Label ("Select Food for [Creature Name]")
│   ├── ScrollContainer
│   │   └── VBoxContainer (FoodList)
│   └── Button (CancelButton)
```

**Create file**: `scenes/windows/food_selector.gd`

```gdscript
extends Panel

var target_creature: CreatureData

@onready var title_label = $VBoxContainer/Label
@onready var food_list = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var cancel_button = $VBoxContainer/CancelButton

func _ready():
	cancel_button.pressed.connect(_on_cancel)
	populate_food_list()

	# Center on screen
	position = (get_viewport_rect().size - size) / 2

func setup(creature: CreatureData):
	target_creature = creature
	if title_label:
		title_label.text = "Select Food for %s" % creature.name

func populate_food_list():
	# Clear existing
	for child in food_list.get_children():
		child.queue_free()

	var inventory_manager = GameManager.inventory_manager
	var player_inv = GameManager.player_data.inventory

	# Get all food items in inventory
	var food_items = inventory_manager.get_items_by_type(GlobalEnums.ItemType.FOOD)

	var has_food = false
	for item_id in food_items:
		if player_inv.has(item_id) and player_inv[item_id] > 0:
			has_food = true
			_create_food_button(item_id, player_inv[item_id])

	if not has_food:
		var label = Label.new()
		label.text = "No food in inventory!\nBuy food from shop (F6)"
		food_list.add_child(label)

func _create_food_button(item_id: String, quantity: int):
	var item = GameManager.inventory_manager.get_item_resource(item_id)
	if not item:
		return

	var hbox = HBoxContainer.new()

	var button = Button.new()
	button.text = "%s (x%d)" % [item.item_name, quantity]
	button.custom_minimum_size.x = 300
	button.pressed.connect(_on_food_selected.bind(item_id))
	hbox.add_child(button)

	# Show stat multiplier if not 1.0
	if item.stat_boost_multiplier != 1.0:
		var boost_label = Label.new()
		boost_label.text = "+%d%% bonus" % int((item.stat_boost_multiplier - 1.0) * 100)
		boost_label.modulate = Color.GREEN
		hbox.add_child(boost_label)

	food_list.add_child(hbox)

func _on_food_selected(item_id: String):
	# Assign food to creature
	GameManager.facility_manager.assign_food_to_creature(target_creature, item_id)
	queue_free()

func _on_cancel():
	queue_free()
```

**Connect in game_scene.gd**:
```gdscript
# In _ready()
SignalBus.food_selection_requested.connect(_on_food_selection_requested)

func _on_food_selection_requested(creature: CreatureData):
	var selector_scene = preload("res://scenes/windows/food_selector.tscn")
	var selector = selector_scene.instantiate()
	add_child(selector)
	selector.setup(creature)
```

**Why**: Popup shows all food items in inventory with quantities. Clicking a food assigns it to the creature. Shows stat boost for premium foods (future feature). Closes after selection.

---

#### Step 17: Create simple inventory UI (optional but recommended)

**Create file**: `scenes/windows/inventory_window.tscn`

**Scene structure**:
```
Panel (InventoryWindow)
├── VBoxContainer
│   ├── Label ("Inventory")
│   ├── ScrollContainer
│   │   └── VBoxContainer (ItemList)
│   └── Button (CloseButton)
```

**Create file**: `scenes/windows/inventory_window.gd`

```gdscript
extends Panel

@onready var item_list = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	SignalBus.item_added.connect(_on_inventory_changed)
	SignalBus.item_removed.connect(_on_inventory_changed)

	refresh_inventory()

	# Center on screen
	position = (get_viewport_rect().size - size) / 2

func _on_close_pressed():
	queue_free()

func _on_inventory_changed(_item_id: String = "", _quantity: int = 0):
	refresh_inventory()

func refresh_inventory():
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()

	var inventory_manager = GameManager.inventory_manager
	var player_inv = GameManager.player_data.inventory

	if player_inv.is_empty():
		var label = Label.new()
		label.text = "No items"
		item_list.add_child(label)
		return

	# Display each item
	for item_id in player_inv.keys():
		var quantity = player_inv[item_id]
		var item_resource = inventory_manager.get_item_resource(item_id)

		if item_resource:
			var hbox = HBoxContainer.new()

			var name_label = Label.new()
			name_label.text = item_resource.item_name
			name_label.custom_minimum_size.x = 200
			hbox.add_child(name_label)

			var qty_label = Label.new()
			qty_label.text = "x" + str(quantity)
			hbox.add_child(qty_label)

			item_list.add_child(hbox)
```

**Add to game_scene.gd** (hotkey to open):

```gdscript
func _input(event):
	if event.is_action_pressed("ui_text_backspace"):  # I key
		_open_inventory()

func _open_inventory():
	var inv_scene = preload("res://scenes/windows/inventory_window.tscn")
	var inv_window = inv_scene.instantiate()
	add_child(inv_window)
```

**Why**: Players need to see what items they have. Simple scrollable list shows item name and quantity. I key opens inventory.

---


#### Step 18: Add week advancement blocked notification

**File**: `scenes/view/game_scene.gd`

**In `_ready()`, add signal connection**:
```gdscript
SignalBus.week_advancement_blocked.connect(_on_week_advancement_blocked)
```

**Add function**:
```gdscript
func _on_week_advancement_blocked(reason: String, creatures: Array):
	print("⚠️ Cannot advance week: %s" % reason)
	for creature in creatures:
		if creature is CreatureData:
			print("  - %s needs food" % creature.name)

	# TODO: Show popup with creature list and message
	# For now, visual feedback: flash the facility cards with red tint
```

**Why**: Player gets immediate feedback when trying to advance week without assigning food. Console shows which creatures need food. Future: popup with creature names and button to dismiss.

---

#### Step 19: Update shop to sell food

**Update existing shop .tres or create new ShopEntry**:

**In your ShopResource** (e.g., `resources/shops/general_shop.tres`):
1. Add ShopEntry:
   - `entry_type`: ITEM
   - `item_id`: "food_basic"
   - `price`: 10
   - `stock`: -1 (unlimited)
2. Add ShopEntry:
   - `entry_type`: ITEM
   - `item_id`: "food_premium"
   - `price`: 25
   - `stock`: -1 (unlimited)

**Update `scripts/shop_manager.gd`**:

**Find the `ITEM` case in `purchase()` function**:

**Replace**:
```gdscript
ShopEntry.ShopEntryType.ITEM:
	print("Item purchase not yet implemented")
	SignalBus.shop_purchase_failed.emit("Item system not implemented")
	return false
```

**With**:
```gdscript
ShopEntry.ShopEntryType.ITEM:
	# Add item to inventory
	if not GameManager.inventory_manager.add_item(entry.item_id, 1):
		SignalBus.shop_purchase_failed.emit("Failed to add item to inventory")
		return false

	print("Purchased item: ", entry.item_id)
	return true
```

**Why**: Players need a way to acquire food. Shop integration provides renewable food source. Basic food for everyday use, premium food for bulk efficiency.

---

### Summary

**New Systems**:
1. **Item System**: Generic item framework with types, stacking, and stat boost multipliers
2. **Inventory System**: Player storage with add/remove/check operations
3. **Food Assignment**: Each creature in a facility needs food assigned via UI
4. **Food Slots**: Clickable slots in FacilityCard to select food from inventory
5. **Food Selection UI**: Popup showing available foods with quantities
6. **Week Validation**: Week advancement blocked until all creatures have food
7. **Food Consumption**: Assigned food consumed when training runs
8. **Stat Boosts**: Food items support multipliers for future training bonuses

**Key Files Created**:
- `core/managers/inventory_manager.gd` (instance in GameManager)
- `resources/items/food_basic.tres` (1.0x multiplier)
- `resources/items/food_premium.tres` (1.5x multiplier - 50% bonus)
- `scenes/windows/food_selector.tscn/gd` (food picker UI)
- `scenes/windows/inventory_window.tscn/gd` (optional general inventory)

**Key Files Modified**:
- `core/global_enums.gd` - ItemType enum
- `resources/item_resource.gd` - stat_boost_multiplier property
- `resources/player_data.gd` - inventory dictionary
- `core/managers/facility_manager.gd` - food assignment tracking and consumption
- `core/game_manager.gd` - InventoryManager instance and week validation
- `core/signal_bus.gd` - food assignment and week blocking signals
- `core/save_manager.gd` - inventory persistence
- `resources/save_game.gd` - inventory storage
- `scripts/shop_manager.gd` - item purchasing
- `scenes/card/facility_card.tscn` - food slot buttons added
- `scenes/card/facility_card.gd` - food slot UI logic and signal connections
- `scenes/view/game_scene.gd` - week blocked notification handler

**Gameplay Flow**:
1. Player drags creature to facility
2. Food slot button appears below creature (shows "+" in red)
3. Player clicks food slot → Food selector popup opens
4. Food selector shows all food in inventory with quantities
5. Player selects food → Food assigned to creature (button shows 🍖)
6. Player tries to advance week
7. GameManager validates: all creatures have food assigned?
   - **Yes**: Week advances, food consumed, training runs, assignments cleared
   - **No**: Week blocked, console shows which creatures need food
8. Player buys more food from shop as needed
9. Repeat for next week
10. Inventory and assignments persist through save/load

**Future Extensions Ready to Implement**:
1. **Stat Boost System**: Activities read `stat_boost_multiplier` from consumed food
   - Modify activity `run_activity()` to accept multiplier parameter
   - Apply multiplier to stat gains (e.g., +5 STR becomes +7 STR with 1.5x food)
2. **Food Variety**: More food types with different multipliers
   - Basic Food: 1.0x (normal)
   - Premium Food: 1.5x (+50% bonus) - already created
   - Luxury Food: 2.0x (+100% bonus)
   - Specialized Foods: Boost specific stats (STR food, AGI food, INT food)
3. **Bulk Assignment**: Right-click food slot to "Fill All with [Food Type]"
4. **Food Preferences**: Creatures prefer certain foods (species-based)
5. **Food Production**: Facility that generates food over time
6. **Food Spoilage**: Food expires after X weeks if not used
7. **Auto-Feed**: Toggle to automatically assign same food each week

**Why This Design Works**:
- ✅ Per-creature food control (not per-facility bulk)
- ✅ UI-driven selection (click slot, pick food)
- ✅ Week blocked until all fed (validates before progression)
- ✅ Food consumed on training (removed from inventory)
- ✅ Stat boost ready (multiplier in ItemResource)
- ✅ Assignments cleared after use (forces weekly management)
- ✅ Extensible for future features (preferences, spoilage, etc.)

---

## Completed Implementations

### ✅ Recent Bug Fixes & UI Improvements

**Quest Creature Turn-In Bug Fix:**
- Fixed creatures not being removed from facilities when turned in for quests
- FacilityManager now listens to `creature_removed` signal
- FacilityCard listens to `facility_unassigned` signal for visual updates
- Signal-driven architecture ensures proper cleanup

**Auto-Place Facility on Unlock:**
- Created BalancedTrainingActivity (+3 to all stats per week)
- Added `unlock_facility` export variable to FacilitySlot
- Slot 4 auto-places "Balanced Training Dojo" when unlocked
- EditorScript updated to generate 4 facility types

**Quest Creature Selector UI:**
- Enabled text wrapping (AUTOWRAP_WORD_SMART) for long tag lists
- Increased button size to 220x140 for better readability
- Reduced grid columns from 4 to 3 for more space
- Tags now display properly without extending off screen

**Debug Popup Disabled:**
- Removed automatic debug popup on game start
- Can be re-enabled by uncommenting in game_scene.gd

**Files Modified:**
- `core/managers/facility_manager.gd` - Auto-unassign on creature removal
- `scenes/card/facility_card.gd` - Listen to facility_unassigned signal
- `scenes/card/facility_slot.gd` - Auto-place facility on unlock
- `scenes/windows/quest_creature_selector.gd/.tscn` - Text wrapping and layout
- `scenes/view/game_scene.gd` - Disabled debug popup, loaded 3 facilities into slots

**Files Created:**
- `resources/activities/balanced_training.gd` - Balanced training activity
- `resources/facilities/balanced_training.tres` - 4th facility resource

---

### ✅ Additional Training Facilities (Agility & Intelligence)
**Implemented new training facilities for all stat types:**

**Features:**
- Created `AgilityTrainingActivity` and `IntelligenceTrainingActivity` classes
- Generated 3 facility .tres files (strength, agility, intelligence)
- Each facility trains one stat (+5 per week)
- All activities auto-grant training tags when thresholds are met
- EditorScript for easy facility .tres generation

**Files Created:**
- `resources/activities/agility_training.gd` - Agility training activity class
- `resources/activities/intelligence_training.gd` - Intelligence training activity class
- `scripts/generate_facilities.gd` - EditorScript to generate facility resources
- `resources/facilities/strength_training.tres` - Strength facility
- `resources/facilities/agility_training.tres` - Agility facility
- `resources/facilities/intelligence_training.tres` - Intelligence facility

**Facilities:**
1. **Strength Training Grounds**: +5 STR per week, 3 creature capacity
2. **Agility Training Course**: +5 AGI per week, 3 creature capacity
3. **Study Hall**: +5 INT per week, 3 creature capacity

**Note:** To use these facilities in-game, load them in game_scene.gd or GameManager and assign to FacilitySlots.

---

### ✅ Creature Tag System (Resource-Based)
**Implemented flexible resource-based tag system with multiple categories:**

**Features:**
- Resource-based .tres tag definitions (13 tags created)
- TagManager static utility for all tag operations
- Auto-assign species tags during creature generation
- Auto-grant training tags when stat thresholds reached
- Multi-category tags (e.g., "Armored" can be SPECIES + TRAINING)
- UI integration (stats popup and quest selector show tags)
- Signal-driven updates (creature_tag_added/removed)
- Lazy loading with performance caching
- Persists in save/load system

**Tag Categories:**
- SPECIES: Innate tags from species
- TRAINING: Earned through activities
- BREEDING: Inherited from parents (future)
- SPECIAL: Event/quest rewards (future)
- NEGATIVE: Debuffs/challenges (future)

**Species Tags (9 total):**
- Scuttleguard: Armored, Defensive, Sturdy
- Slime: Adaptable, Amorphous, Regenerative
- Wind Dancer: Swift, Magical, Aerial

**Training Tags (4 total):**
- STR ≥18: Battle-Hardened | STR ≥20: Armored
- AGI ≥18: Agile Expert | AGI ≥20: Swift
- INT ≥15: Scholar
- All stats ≥12: Disciplined

**Files Created:**
- `resources/tag_resource.gd` - TagResource class
- `scripts/tag_manager.gd` - Static tag utility
- `scripts/generate_tags.gd` - EditorScript for tag generation
- `resources/tags/*.tres` - 13 tag resource files
- Updated: `core/global_enums.gd`, `core/signal_bus.gd`, `resources/creature_data.gd`
- Updated: `scripts/creature_generation.gd`, `resources/activities/strength_training.gd`
- Updated: `scenes/windows/creature_stats_popup.gd/.tscn`, `scenes/windows/quest_creature_selector.gd`

---

### ✅ Quest System with Resource-Based Design
**Implemented complete quest system with multi-stage quest lines:**

**Features:**
- Resource-based quest definitions (QuestResource, QuestRequirement, QuestReward)
- QuestManager instance in GameManager (not autoload)
- Quest validation with stat and species requirements
- Quest chain with prerequisites
- Creature turn-in system with selection UI
- Save/load quest progress
- "The Collector's Needs" quest line (5 quests)
- Q key to open quest log
- Visual creature cleanup on turn-in via creature_removed signal
- Quest resources loaded dynamically from resources/quests/ folder
- EditorScript for programmatic quest .tres generation

**Architecture:**
- **QuestRequirement**: Defines creature requirements (species, stats, quantity, tags)
- **QuestReward**: Gold, XP, special unlocks
- **QuestResource**: Complete quest definition with validation
- **QuestManager**: Quest progression, validation, completion (instance, not autoload)
- **QuestWindow**: Quest log UI
- **QuestCreatureSelector**: Creature selection for turn-ins (only shows matching creatures)

**Quest Line "The Collector's Needs":**
1. COL-01 "First Guardian": 1 Scuttleguard STR ≥ 15 → 300g
2. COL-02 "Swift Scout": 1 Wind Dancer AGI ≥ 15 → 400g
3. COL-03 "Clever Companion": 1 any creature INT ≥ 12 → 500g
4. COL-04 "Elite Squad": 2 creatures all stats ≥ 12 → 800g
5. COL-05 "Ultimate Champion": 1 creature all stats ≥ 18 → 2000g + title

**Files Created:**
- `resources/quest_requirement.gd`
- `resources/quest_reward.gd`
- `resources/quest_resource.gd`
- `resources/quests/COL-01.tres through COL-05.tres` (quest resource files)
- `core/managers/quest_manager.gd` (instance, not autoload)
- `scenes/windows/quest_window.tscn/gd`
- `scenes/windows/quest_creature_selector.tscn/gd`
- `scripts/generate_quests.gd` (EditorScript for quest generation)

**Signals Added:**
- `quest_accepted(quest)` - Quest becomes active
- `quest_completed(quest)` - Quest successfully turned in
- `quest_turn_in_failed(quest, missing)` - Turn-in validation failed
- `quest_turn_in_started(quest)` - Opens creature selector
- `quest_log_opened()` - Quest window opened
- `quest_log_closed()` - Quest window closed
- `creature_removed(creature)` - Creature removed from player data

**Key Technical Notes:**
- Creature selector filters to only show matching creatures
- Visual cleanup: CreatureDisplay and DragDropComponent nodes removed on turn-in
- Quest resources support typed arrays (Array[QuestRequirement]) in .tres files
- Dynamic quest loading via DirAccess.open("res://resources/quests/")
- QuestManager follows FacilityManager pattern (instance in GameManager)

**Future Extensibility:**
- Tags system ready (required_tags array)
- Item rewards ready (items array)
- Easy to create new quests as .tres files
- Multi-part requirements supported
- EditorScript available for batch quest generation

---

### ✅ Resource-Based Shop System
**Implemented flexible, resource-based shop system for creature and item purchases:**

**Features:**
- Created `ItemResource`, `ShopEntry`, and `ShopResource` classes
- Built reusable `ShopWindow` UI (1200x800, centered panel)
- Implemented `ShopManager` utility class for purchase logic
- Added gold management via `SignalBus` (`gold_change_requested` signal)
- Support for 3 purchase types: CREATURE, ITEM, SERVICE
- Stock tracking (limited/unlimited quantities)
- F6 hotkey to open test shop

**Architecture:**
- **ItemResource**: Defines inventory items (potions, equipment) - reusable across systems
- **ShopEntry**: Defines what's for sale with price, stock, and type-specific data
- **ShopResource**: Shop inventory with vendor info and array of ShopEntries
- **ShopManager**: Static utility class for validation and SignalBus integration
- Creature purchases generate directly (bypass inventory)
- Item/Service purchases for future expansion

**Files Created:**
- `resources/item_resource.gd` - Item data structure
- `resources/shop_entry.gd` - Shop entry definition
- `resources/shop_resource.gd` - Shop configuration with stock tracking
- `scripts/shop_manager.gd` - Purchase logic and validation
- `scenes/windows/shop_window.tscn/gd` - Shop UI
- `scenes/ui/shop_item_entry.tscn/gd` - Individual item display component

**Signals Added:**
- `shop_opened(shop)` - Emitted when shop window opens
- `shop_closed()` - Emitted when shop closes
- `shop_purchase_completed(item_name, cost)` - Successful purchase
- `shop_purchase_failed(reason)` - Purchase failure with reason
- `gold_change_requested(amount)` - Request gold change (negative = spend)

**Gold Management:**
- GameManager listens for `gold_change_requested` signal
- Validates and updates `player_data.gold`
- Prevents negative gold
- Emits `gold_changed` for UI updates

**Bug Fixes:**
- Fixed shop item visibility with async `await ready` in setup
- Removed nested ScrollContainer that prevented item display
- Added proper node path after fixing scene structure

---

### ✅ Creature Generation with Species-Based Stat Curves
**Implemented procedural creature generation with species profiles:**

**Features:**
- Created `CreatureGenerator` utility class (static functions)
- Species-specific stat profiles using normal distribution
- Random name generation per species
- Helper function in GameManager for easy creature addition

**Species Stat Profiles:**
- **SCUTTLEGUARD** (Tank): STR 12±3, AGI 6±2, INT 8±2
- **SLIME** (Balanced): All stats 8±2
- **WIND_DANCER** (Mage): STR 6±2, AGI 12±3, INT 10±2

**Files Created:**
- `scripts/creature_generation.gd` - CreatureGenerator class

**Changes:**
- Updated GameManager to use `CreatureGenerator.generate_creature()`
- Replaced hardcoded starter creatures with generated ones
- Added `add_generated_creature()` helper to GameManager

---

### ✅ Facility Slot Unlock Bug Fix
**Fixed unlocked slots not accepting drops and set unique slot indices:**

**Bug Fixed:**
- Unlocked facility slots now properly accept facility drops after unlocking
- Root cause: Drop zone was only created in `_ready()` for initially unlocked slots
- Solution: Call `_setup_drop_zone()` in `attempt_unlock()` after removing overlay
- Slot indices properly set (0, 1, 2, 3) for accurate unlock messages

**Changes:**
- `scenes/card/facility_slot.gd:187` - Added `_setup_drop_zone()` call in `attempt_unlock()`
- `scenes/view/game_scene.tscn:52,60,69` - Set unique slot_index values (1, 2, 3)
- `core/signal_bus.gd:31` - Added `facility_slot_unlocked` signal
- `scenes/view/game_scene.gd:290` - Fixed slot reference from `$FacilitySlot` to `$FacilitySlot1`

---

### ✅ FacilitySlot Scene Conversion & Drop Zone Bug Fix
**Converted FacilitySlot from script-only to scene-based and fixed critical drop bug:**

**Features**:
- Converted FacilitySlot from programmatic creation to scene-based
- Created `facility_slot.tscn` for visual editing in Godot editor
- FacilitySlot instances now placed directly in game_scene.tscn as children
- Updated game_scene.gd to work with scene-based slots (signal connection only)
- Removed programmatic slot creation code

**Bug Fixed**:
- **Fixed facility drop zone bug** - Facility slots no longer stop accepting drops after removing all creatures
  - Root cause: `queue_free()` doesn't remove nodes immediately, causing duplicates
  - Old drag components stayed in tree and blocked mouse input after being marked for deletion
  - Solution: Changed to `free()` in `update_slots()` for immediate removal
  - Applies to both CreatureDrag components and creature sprites

**Files Modified**:
- `scenes/card/facility_card.gd` - Changed `queue_free()` to `free()` in update_slots()
- `scenes/view/game_scene.gd` - Updated to work with scene-based FacilitySlots
- `scenes/view/game_scene.tscn` - FacilitySlot instances placed as children

**Files Created**:
- `scenes/card/facility_slot.tscn` - Scene for FacilitySlot visual editing

**Technical Details**:
- `queue_free()` marks nodes for deletion at end of frame
- During slot updates, new drag components were created before old ones were removed
- Result: Duplicate drag components with same names blocking input
- `free()` provides immediate removal, preventing input conflicts

### ✅ Creature Stats Popup & Click Detection
**Created popup system to view creature stats with click detection:**

**Features**:
- Click on creatures in world to view stats popup
- Shows: name, species, strength, agility, intelligence
- Click detection integrated into DragDropComponent
- Distinguishes clicks from drags (10px threshold)
- `clicked()` signal emitted for non-drag clicks
- Works alongside existing drag/drop functionality

**Files Created**:
- `scenes/windows/creature_stats_popup.tscn` - Popup UI scene
- `scenes/windows/creature_stats_popup.gd` - Popup logic and data display

**Bug Fixes**:
1. **Fixed facility activity execution** - Activities now properly modify stats
   - Changed from base `ActivityResource.new()` to actual `StrengthTrainingActivity` class
   - Activities execute their `run_activity()` implementation correctly

2. **Fixed creature duplication** - Creatures no longer duplicate when moved between slots
   - Fixed indentation bug in `facility_card.gd` line 142
   - Same-facility moves now properly remove creature from source slot

**Signals Updated**:
- Added `creature_clicked(creature_data)` to SignalBus
- Connected in game_scene to instantiate popup

### ✅ Unified Drag & Drop Component System
**Architecture**: Layered Control nodes with z-indexing for proper input priority

**DragDropComponent Class** (`scripts/drag_drop_component.gd`):
- Reusable component for all drag/drop operations
- Extends Control, purely for interaction (no visual elements)
- **Drag Types**: CREATURE, FACILITY_CARD, CUSTOM
- **Configurable Flags**:
  - `can_drag`: Enable/disable drag initiation (drop-only zones use `false`)
  - `can_accept_drops`: Enable drop acceptance
  - `hide_on_drag`: Auto-hide source node during drag
- **Custom Validation**: `custom_can_drop_callback` for complex drop logic
- **Signals**: `drag_started`, `drag_ended`, `drop_received`

**Layered Architecture Pattern**:
All drag/drop uses z-indexed layers for proper input handling:
- **Layer 1 (z:100)**: Base drop zones (cover full area, drop-only)
- **Layer 2 (z:101-200)**: Individual drag sources (positioned over specific elements)

**Implementations**:
1. **Creatures in World**:
   - `CreatureDrag_[name]` components (z:200) as siblings to container
   - Follow creatures via global positioning in `_process()`
   - Separate from visual CreatureDisplay nodes

2. **Creature Container**:
   - `ContainerDropZone` (z:100) drop-only base layer
   - Accepts creatures from world or facilities
   - Repositions world creatures or spawns from facilities

3. **Facility Cards**:
   - `FacilityDrag` (z:100) for dragging card + accepting creature drops
   - `CreatureDrag_0`, `CreatureDrag_1` (z:101) per creature slot
   - All as direct children of FacilityCard for proper hierarchy

4. **Facility Slots**:
   - `FacilitySlotDropZone` (z:100) drop-only
   - Accepts facility card drops for placement/swapping

**Key Features**:
- Completely agnostic of visual elements (pure interaction layer)
- No native `_get_drag_data/_can_drop_data/_drop_data` in game code
- Proper mouse event propagation via z-index and child ordering
- Preview generation with customizable alpha
- Drop validation prevents overfilling facilities
- **See `DRAG_DROP_CHANGES.md` for migration documentation**

### ✅ Facility Cards with Drag & Drop
- Created FacilityCard UI scene and script
- Added drag functionality to creatures using Control child nodes
- Implemented drop detection on facility cards
- Visual feedback during drag (semi-transparent preview, highlighting)
- Creatures return to view if not dropped on facility
- CreatureContainer accepts drops for repositioning
- Automatic activity execution on assignment

### ✅ Facility & Activity System
- Created base ActivityResource class with overridable run_activity
- Created FacilityResource class managing multiple activities
- Example activities: StrengthTraining, SpeciesChange
- Activities can check conditions and modify creatures
- Signals for activity events in SignalBus
- Test facility setup in GameManager

### ✅ Game Initialization Flow
- Created PlayerData resource class
- Set up GameManager initialization
- Implemented SignalBus pattern
- Connected game_scene to show debug popup
- Added creature with species to starter data

### ✅ SignalBus Setup
- Created centralized signal definitions
- Added to autoload in correct order
- Connected game_started signal
- Connected player_data_initialized signal

### ✅ Creature Display System
- Spawning creatures in CreatureContainer
- Container boundary constraints with padding
- Idle/Walking state machine
- Directional animations (walk-up, walk-down, walk-left, walk-right)
- FacingDirection enum in GlobalEnums

### ✅ Emote Bubble System
- Random emote display above creatures
- 15 different emote types
- Timer-based with configurable intervals
- Pop-in animation with elastic tween
- Auto-cleanup after duration

### ✅ Save/Load System
- SaveManager singleton for all persistence
- Resource-based saves (SaveGame class)
- F5/F9 quick save/load
- Main menu continue button
- Save metadata and versioning
- Refactored from GameManager to dedicated SaveManager

---

## Quick Reference

### Common Patterns

#### Adding a New Signal
1. Define in `SignalBus`
2. Emit from source system
3. Connect in receiving systems
4. Update this document

#### Creating New UI Popup
1. Create scene in `scenes/windows/`
2. Create accompanying script
3. Connect to relevant SignalBus signals
4. Preload and instantiate from game_scene

#### Adding Game Features
1. Define needed signals in SignalBus
2. Implement logic in GameManager or appropriate system
3. Create UI components if needed
4. Wire up signal connections
5. Test the flow

#### Using DragDropComponent

**For Drag Sources** (things you can pick up):
```gdscript
var drag_component = DragDropComponent.new()
drag_component.name = "MyDrag"
drag_component.drag_type = DragDropComponent.DragType.CREATURE  # or FACILITY_CARD, CUSTOM
drag_component.drag_data_source = source_node  # The visual node being dragged
drag_component.mouse_filter_mode = Control.MOUSE_FILTER_STOP
drag_component.z_index = 101  # Above drop zones

# Position and size over the draggable element
drag_component.position = element_position
drag_component.size = element_size

# Connect signals
drag_component.drag_started.connect(func(data): pass)
drag_component.drag_ended.connect(func(successful): pass)

add_child(drag_component)
```

**For Drop Zones** (areas that accept drops):
```gdscript
var drop_zone = DragDropComponent.new()
drop_zone.name = "MyDropZone"
drop_zone.drag_type = DragDropComponent.DragType.CREATURE
drop_zone.can_accept_drops = true
drop_zone.can_drag = false  # Drop-only zone
drop_zone.mouse_filter_mode = Control.MOUSE_FILTER_STOP
drop_zone.z_index = 100  # Below drag sources

# Fill the droppable area
drop_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
drop_zone.set_offsets_preset(Control.PRESET_FULL_RECT)

# Custom validation (optional)
drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
    return data.has("creature") and can_accept(data.creature)

# Connect drop signal
drop_zone.drop_received.connect(_on_drop_received)

add_child(drop_zone)
```

**Key Principles**:
- Drop zones at z:100, drag sources at z:101+
- Drop-only zones use `can_drag = false`
- Drag sources use `drag_data_source` to reference visual elements
- Components are siblings or parents to avoid mouse filter conflicts
- Use global positioning for components outside their parent's hierarchy

### File Structure
```
project/
├── core/
│   ├── game_manager.gd (Game logic)
│   ├── save_manager.gd (Persistence)
│   ├── signal_bus.gd (Signal hub)
│   ├── global_enums.gd (Constants)
│   └── managers/
│       └── facility_manager.gd (Facility assignments)
├── resources/
│   ├── creature_data.gd
│   ├── player_data.gd
│   ├── save_game.gd
│   ├── facility_data.gd
│   └── activities/ (ActivityResource subclasses)
├── scripts/
│   └── drag_drop_component.gd (Unified drag/drop)
├── scenes/
│   ├── view/ (Main scenes)
│   │   ├── main_menu.tscn/gd
│   │   └── game_scene.tscn/gd
│   ├── windows/ (Popups)
│   │   ├── debug_popup.tscn/gd
│   │   └── emote_bubble.tscn/gd
│   ├── card/ (Facility UI)
│   │   ├── facility_card.tscn/gd
│   │   ├── facility_slot.gd
│   │   └── week_display.tscn/gd
│   └── entities/ (Game objects)
│       └── creature_display.tscn/gd
└── assets/
    ├── sprites/creatures/
    └── emotes/
```

---

## Notes for Future Development

**SignalBus Best Practices:**
- SignalBus pattern keeps systems decoupled
- Always emit signals with relevant data
- Check if data exists before emitting
- Remember to disconnect signals when nodes are freed

**DragDropComponent Best Practices:**
- Always use DragDropComponent for drag/drop (never native methods)
- Layer drop zones at z:100, drag sources at z:101+
- Use `can_drag = false` for drop-only zones
- Keep components separate from visual nodes
- Use global positioning for components outside parent hierarchy
- Clean up drag components when visual nodes are freed

**General Development:**
- Use preload() for scenes that will be instantiated multiple times
- Test drag/drop with different z-index configurations if issues arise
- Check mouse_filter settings if input isn't working as expected

---

## Next Possible Features

Potential implementations ready to guide:
- Week advancement system with UI
- Creature training mechanics
- Facility management
- Save/Load system
- Settings menu
- Creature detail view
- Resource management (gold spending)
- Activity system

*Request any feature and steps will appear in the Implementation Steps section above*
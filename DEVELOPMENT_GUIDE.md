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

**FacilityManager** (accessed via `GameManager.facility_manager`)
- Tracks creature-to-facility assignments
- Processes all activities on week advancement
- Handles registration/unregistration of creatures
- Dictionary: `{facility: [creatures]}`
- Created and managed by GameManager

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

### 🎯 Quest System Implementation

**Overview**: Building a resource-based quest system with multi-stage quest lines, stat requirements, species requirements, and rewards. Based on quest example but adapted to current creatures (Scuttleguard, Slime, Wind_Dancer) and stats (strength, agility, intelligence).

**Architecture Design:**

```
QuestResource (defines single quest)
├── quest_id: String
├── quest_title: String
├── quest_giver: String
├── description: String
├── dialogue: String
├── prerequisites: Array[String] (quest IDs)
├── requirements: Array[QuestRequirement]
└── rewards: QuestReward

QuestRequirement (what creatures are needed)
├── quantity: int (how many creatures needed)
├── species_filter: GlobalEnums.Species (optional - any species if null)
├── min_strength: int
├── min_agility: int
├── min_intelligence: int
└── tags: Array[String] (future - for extensibility)

QuestReward
├── gold: int
├── experience: int
├── items: Array[ItemResource] (future)
└── unlock_message: String (special unlocks)

QuestManager (Instance in GameManager)
├── all_quests: Dictionary[String, QuestResource]
├── active_quests: Array[String]
├── completed_quests: Array[String]
└── Functions: load_quests, accept_quest, validate_creatures, complete_quest
```

**Quest Line: "The Collector's Needs"**

Adapted from the example with current creatures:

1. **"First Guardian"** (COL-01)
   - Need: 1 Scuttleguard with STR ≥ 15
   - Reward: 300 gold

2. **"Swift Scout"** (COL-02)
   - Prerequisite: COL-01
   - Need: 1 Wind Dancer with AGI ≥ 15
   - Reward: 400 gold

3. **"Clever Companion"** (COL-03)
   - Prerequisite: COL-02
   - Need: 1 creature (any species) with INT ≥ 12
   - Reward: 500 gold

4. **"Elite Squad"** (COL-04)
   - Prerequisite: COL-03
   - Need: 2 creatures with STR ≥ 12, AGI ≥ 12, INT ≥ 12
   - Reward: 800 gold

5. **"Ultimate Champion"** (COL-05)
   - Prerequisite: COL-04
   - Need: 1 creature with STR ≥ 18, AGI ≥ 18, INT ≥ 18
   - Reward: 2000 gold, unlock "Master Collector" title

---

#### Step 1: Create QuestRequirement Resource

**File:** `resources/quest_requirement.gd` (NEW FILE)

```gdscript
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
```

**Why:** Core validation logic for creature requirements. Extensible with tags for future features. Provides UI-friendly descriptions.

---

#### Step 2: Create QuestReward Resource

**File:** `resources/quest_reward.gd` (NEW FILE)

```gdscript
# resources/quest_reward.gd
extends Resource
class_name QuestReward

@export var gold: int = 0
@export var experience: int = 0

# Future: Item rewards
# @export var items: Array[ItemResource] = []

# Special unlocks (e.g., "Unlocked new facility", "Gained Master Collector title")
@export var unlock_message: String = ""

func has_rewards() -> bool:
	return gold > 0 or experience > 0 or unlock_message != ""

func get_description() -> String:
	var parts: Array[String] = []

	if gold > 0:
		parts.append("%d Gold" % gold)
	if experience > 0:
		parts.append("%d XP" % experience)
	if unlock_message != "":
		parts.append(unlock_message)

	return "\n".join(parts)
```

**Why:** Encapsulates all reward types. Easy to extend with items, unlocks, titles, etc.

---

#### Step 3: Create QuestResource

**File:** `resources/quest_resource.gd` (NEW FILE)

```gdscript
# resources/quest_resource.gd
extends Resource
class_name QuestResource

# Quest identification
@export var quest_id: String = ""
@export var quest_title: String = "Untitled Quest"
@export var quest_giver: String = "Unknown"

# Quest content
@export_multiline var description: String = ""
@export_multiline var dialogue: String = ""

# Quest chain
@export var prerequisite_quest_ids: Array[String] = []

# Requirements (can have multiple parts)
@export var requirements: Array[QuestRequirement] = []

# Rewards
@export var reward: QuestReward = null

# Check if player meets prerequisites
func prerequisites_met(completed_quest_ids: Array[String]) -> bool:
	for prereq_id in prerequisite_quest_ids:
		if not prereq_id in completed_quest_ids:
			return false
	return true

# Validate if provided creatures meet all requirements
# Returns: { "valid": bool, "missing": Array[String] }
func validate_creatures(creatures: Array[CreatureData]) -> Dictionary:
	var result = {
		"valid": true,
		"missing": []
	}

	for req in requirements:
		var matching_count = 0

		# Count how many creatures match this requirement
		for creature in creatures:
			if req.creature_matches(creature):
				matching_count += 1
				if matching_count >= req.quantity:
					break

		# Check if we have enough
		if matching_count < req.quantity:
			var needed = req.quantity - matching_count
			result.valid = false
			result.missing.append("Need %d more: %s" % [needed, req.get_description()])

	return result

# Get total requirements summary for UI
func get_requirements_summary() -> String:
	var parts: Array[String] = []
	for i in range(requirements.size()):
		var req = requirements[i]
		if requirements.size() > 1:
			parts.append("Part %d: %dx %s" % [i + 1, req.quantity, req.get_description()])
		else:
			parts.append("%dx %s" % [req.quantity, req.get_description()])
	return "\n".join(parts)
```

**Why:** Complete quest definition. Self-validating with prerequisite checking and creature validation. Resource-based means you can create quests in Godot editor visually.

---

#### Step 4: Create QuestManager Class

**File:** `core/managers/quest_manager.gd` (NEW FILE)

```gdscript
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
	load_all_quests()

	# Auto-accept first quest in chain (only if no quests active/completed)
	if active_quests.is_empty() and completed_quests.is_empty():
		if all_quests.has("COL-01"):
			accept_quest("COL-01")

# Load quest resources from disk
func load_all_quests():
	all_quests.clear()

	# Load quests from resources folder
	# For now, we'll register them manually
	# Future: Use DirAccess to scan resources/quests/ folder

	register_quest(create_quest_col_01())
	register_quest(create_quest_col_02())
	register_quest(create_quest_col_03())
	register_quest(create_quest_col_04())
	register_quest(create_quest_col_05())

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

# === QUEST DEFINITIONS ===
# Future: Move these to .tres resource files in resources/quests/

func create_quest_col_01() -> QuestResource:
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
	quest.requirements = [req]

	var reward = QuestReward.new()
	reward.gold = 300
	quest.reward = reward

	return quest

func create_quest_col_02() -> QuestResource:
	var quest = QuestResource.new()
	quest.quest_id = "COL-02"
	quest.quest_title = "Swift Scout"
	quest.quest_giver = "The Collector"
	quest.dialogue = "Excellent work! Now I need something fast to scout the perimeter. A Wind Dancer with great agility would be ideal."
	quest.description = "The Collector needs a swift scout."
	quest.prerequisite_quest_ids = ["COL-01"]

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = GlobalEnums.Species.WIND_DANCER
	req.min_agility = 15
	req.requirement_description = "Wind Dancer with AGI ≥ 15"
	quest.requirements = [req]

	var reward = QuestReward.new()
	reward.gold = 400
	quest.reward = reward

	return quest

func create_quest_col_03() -> QuestResource:
	var quest = QuestResource.new()
	quest.quest_id = "COL-03"
	quest.quest_title = "Clever Companion"
	quest.quest_giver = "The Collector"
	quest.dialogue = "Impressive! Now I need a clever creature to help me catalog my collection. Intelligence is what matters here."
	quest.description = "The Collector needs an intelligent assistant."
	quest.prerequisite_quest_ids = ["COL-02"]

	var req = QuestRequirement.new()
	req.quantity = 1
	# No species filter - any species allowed
	req.species_filter = -1
	req.min_intelligence = 12
	req.requirement_description = "Any creature with INT ≥ 12"
	quest.requirements = [req]

	var reward = QuestReward.new()
	reward.gold = 500
	quest.reward = reward

	return quest

func create_quest_col_04() -> QuestResource:
	var quest = QuestResource.new()
	quest.quest_id = "COL-04"
	quest.quest_title = "Elite Squad"
	quest.quest_giver = "The Collector"
	quest.dialogue = "You've proven yourself! I'm expanding my operations and need an elite squad—two well-rounded creatures."
	quest.description = "The Collector needs two elite creatures."
	quest.prerequisite_quest_ids = ["COL-03"]

	var req = QuestRequirement.new()
	req.quantity = 2
	req.species_filter = -1  # Any species
	req.min_strength = 12
	req.min_agility = 12
	req.min_intelligence = 12
	req.requirement_description = "Well-rounded creature (all stats ≥ 12)"
	quest.requirements = [req]

	var reward = QuestReward.new()
	reward.gold = 800
	quest.reward = reward

	return quest

func create_quest_col_05() -> QuestResource:
	var quest = QuestResource.new()
	quest.quest_id = "COL-05"
	quest.quest_title = "Ultimate Champion"
	quest.quest_giver = "The Collector"
	quest.dialogue = "This is it—the final test. I need a true champion, a creature with exceptional abilities across the board. Can you deliver?"
	quest.description = "The Collector seeks the ultimate champion."
	quest.prerequisite_quest_ids = ["COL-04"]

	var req = QuestRequirement.new()
	req.quantity = 1
	req.species_filter = -1  # Any species
	req.min_strength = 18
	req.min_agility = 18
	req.min_intelligence = 18
	req.requirement_description = "Champion (all stats ≥ 18)"
	quest.requirements = [req]

	var reward = QuestReward.new()
	reward.gold = 2000
	reward.unlock_message = "Unlocked: Master Collector Title"
	quest.reward = reward

	return quest
```

**Why:** Central quest management. Handles progression, validation, rewards. Quests are defined in code for now (easy to move to .tres files later). Auto-accepts next quest in chain when prerequisites are met.

---

#### Step 5: Add QuestManager Instance to GameManager

**File:** `core/game_manager.gd`

**Add member variable** at the top of the file (around line 5-10, after other variables):

```gdscript
# Quest management
var quest_manager: QuestManager
```

**In `_ready()` function**, create QuestManager instance (around line 15-20):

```gdscript
func _ready():
	SignalBus.game_started.connect(initialize_new_game)
	SignalBus.gold_change_requested.connect(_on_gold_change_requested)
	SignalBus.facility_assigned.connect(facility_manager.register_assignment)
	SignalBus.facility_unassigned.connect(facility_manager.unregister_assignment)
	SignalBus.week_advanced.connect(facility_manager.process_all_activities)

	# Create quest manager instance (NEW)
	quest_manager = QuestManager.new()
	add_child(quest_manager)
```

**In `initialize_new_game()` function**, initialize quest manager (around line 25-30):

```gdscript
func initialize_new_game():
	# Existing initialization code...
	player_data = PlayerData.new()
	player_data.gold = 1000
	# ... create starter creatures ...

	# Initialize quest manager (NEW)
	quest_manager.initialize()

	SignalBus.player_data_initialized.emit()
```

**Why:** QuestManager as GameManager instance (like FacilityManager). No new autoload needed. Keeps architecture clean.

---

#### Step 6: Update Access to QuestManager

**Throughout the implementation**, replace references to `QuestManager` with `GameManager.quest_manager`:

- In UI scripts: `GameManager.quest_manager.get_available_quests()`
- In signal handlers: `GameManager.quest_manager.complete_quest()`
- Example from quest_window.gd line 863: `var available = GameManager.quest_manager.get_available_quests()`

**Why:** Since QuestManager is now accessed via GameManager, all references need the prefix.

---

#### Step 7: Add Quest Signals to SignalBus

**File:** `core/signal_bus.gd`

**Add at the end of the file** (after existing signals):

```gdscript
# Quest System
signal quest_accepted(quest: QuestResource)
signal quest_completed(quest: QuestResource)
signal quest_turn_in_failed(quest: QuestResource, missing_requirements: Array)
signal quest_log_opened()
signal quest_log_closed()
```

**Why:** Decoupled communication for quest events. UI can react to quest changes without direct dependencies.

---

#### Step 7: Add remove_creature to GameManager

**File:** `core/game_manager.gd`

**Add this function** after the `add_generated_creature()` function (around line 50-60):

```gdscript
func remove_creature(creature: CreatureData):
	if player_data and creature in player_data.creatures:
		player_data.creatures.erase(creature)
		SignalBus.creature_removed.emit(creature)
		print("Removed creature: ", creature.creature_name)
```

**Why:** Quest turn-ins remove creatures from player's collection. Need a way to delete creatures.

---

#### Step 8: Add creature_removed Signal to SignalBus

**File:** `core/signal_bus.gd`

**Add in the Player & Resources section** (around line 18-20):

```gdscript
# Player & Resources
signal gold_change_requested(amount: int)
signal gold_changed(new_amount: int)
signal creature_added(creature: CreatureData)
signal creature_removed(creature: CreatureData)  # NEW
signal creature_stats_changed(creature: CreatureData)
```

**Why:** UI needs to know when creatures are removed (from turn-ins or other systems).

---

#### Step 9: Create QuestWindow UI

**File:** `scenes/windows/quest_window.tscn` (NEW SCENE)

**Create this scene structure in Godot:**
```
QuestWindow (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleBar (HBoxContainer)
│       │   ├── QuestTitle (Label) - "Quest Log"
│       │   └── CloseButton (Button) - "X"
│       ├── HSeparator
│       ├── ContentArea (HBoxContainer)
│       │   ├── QuestList (VBoxContainer) - Left side
│       │   │   ├── QuestListLabel (Label) - "Available Quests"
│       │   │   └── QuestListScroll (ScrollContainer)
│       │   │       └── QuestListContainer (VBoxContainer)
│       │   └── QuestDetails (VBoxContainer) - Right side
│       │       ├── SelectedQuestTitle (Label)
│       │       ├── QuestGiver (Label)
│       │       ├── QuestDialogue (RichTextLabel)
│       │       ├── HSeparator2
│       │       ├── RequirementsLabel (Label) - "Requirements:"
│       │       ├── RequirementsText (RichTextLabel)
│       │       ├── HSeparator3
│       │       ├── RewardsLabel (Label) - "Rewards:"
│       │       ├── RewardsText (RichTextLabel)
│       │       ├── HSeparator4
│       │       └── ActionButtons (HBoxContainer)
│       │           └── TurnInButton (Button) - "Select Creatures"
```

**Configure:**
- QuestWindow: custom_minimum_size = (1200, 700)
- ContentArea: Size flags horizontal = Expand Fill, separation = 20
- QuestList: custom_minimum_size.x = 300
- QuestDetails: Size flags horizontal = Expand Fill

**Attach script:** `scenes/windows/quest_window.gd`

---

#### Step 10: Create QuestWindow Script

**File:** `scenes/windows/quest_window.gd` (NEW FILE)

```gdscript
# scenes/windows/quest_window.gd
extends PanelContainer

@onready var quest_list_container = $MarginContainer/VBoxContainer/ContentArea/QuestList/QuestListScroll/QuestListContainer
@onready var selected_quest_title = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/SelectedQuestTitle
@onready var quest_giver = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/QuestGiver
@onready var quest_dialogue = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/QuestDialogue
@onready var requirements_text = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/RequirementsText
@onready var rewards_text = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/RewardsText
@onready var turn_in_button = $MarginContainer/VBoxContainer/ContentArea/QuestDetails/ActionButtons/TurnInButton
@onready var close_button = $MarginContainer/VBoxContainer/TitleBar/CloseButton

var selected_quest: QuestResource = null

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	turn_in_button.pressed.connect(_on_turn_in_pressed)

	SignalBus.quest_accepted.connect(_on_quest_accepted)
	SignalBus.quest_completed.connect(_on_quest_completed)

	# Center on screen
	position = Vector2(
		(get_viewport_rect().size.x - size.x) / 2,
		(get_viewport_rect().size.y - size.y) / 2
	)

	refresh_quest_list()

func _on_close_pressed():
	SignalBus.quest_log_closed.emit()
	queue_free()

func _on_turn_in_pressed():
	if selected_quest:
		GameManager.quest_manager.current_quest_for_turnin = selected_quest
		SignalBus.quest_turn_in_started.emit(selected_quest)
		# Open creature selection window (to be implemented)
		print("Select creatures to turn in for quest: ", selected_quest.quest_title)

func _on_quest_accepted(quest: QuestResource):
	refresh_quest_list()

func _on_quest_completed(quest: QuestResource):
	refresh_quest_list()
	# Show completion message
	show_quest_completed_popup(quest)

func refresh_quest_list():
	# Clear existing quest buttons
	for child in quest_list_container.get_children():
		child.queue_free()

	# Add active quests
	var available = GameManager.quest_manager.get_available_quests()
	for quest in available:
		var button = Button.new()
		button.text = quest.quest_title
		button.pressed.connect(func(): select_quest(quest))
		quest_list_container.add_child(button)

	# Select first quest by default
	if available.size() > 0:
		select_quest(available[0])
	else:
		clear_quest_details()

func select_quest(quest: QuestResource):
	selected_quest = quest

	# Update UI
	selected_quest_title.text = quest.quest_title
	quest_giver.text = "Quest Giver: " + quest.quest_giver
	quest_dialogue.text = quest.dialogue
	requirements_text.text = quest.get_requirements_summary()

	if quest.reward:
		rewards_text.text = quest.reward.get_description()
	else:
		rewards_text.text = "No rewards"

	turn_in_button.disabled = false

func clear_quest_details():
	selected_quest = null
	selected_quest_title.text = "No Active Quests"
	quest_giver.text = ""
	quest_dialogue.text = ""
	requirements_text.text = ""
	rewards_text.text = ""
	turn_in_button.disabled = true

func show_quest_completed_popup(quest: QuestResource):
	# Future: Show a fancy completion popup
	print("QUEST COMPLETED: ", quest.quest_title)
	if quest.reward:
		print("Rewards: ", quest.reward.get_description())
```

**Why:** Main UI for viewing and interacting with quests. Shows quest details, requirements, rewards. Handles quest selection and turn-in initiation.

---

#### Step 11: Add quest_turn_in_started Signal

**File:** `core/signal_bus.gd`

**Add to Quest System section:**

```gdscript
# Quest System
signal quest_accepted(quest: QuestResource)
signal quest_completed(quest: QuestResource)
signal quest_turn_in_failed(quest: QuestResource, missing_requirements: Array)
signal quest_turn_in_started(quest: QuestResource)  # NEW
signal quest_log_opened()
signal quest_log_closed()
```

**Why:** Notifies when player initiates quest turn-in. Used to open creature selection UI.

---

#### Step 12: Add Quest Window Opener to GameScene

**File:** `scenes/view/game_scene.gd`

**Add after existing InputEvent handling** (around line 20-30, in `_input` or create new function):

```gdscript
func _input(event):
	# Existing code for F5/F9 save/load...

	# Open Quest Log with Q key
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			open_quest_window()

func open_quest_window():
	# Prevent multiple instances
	if get_node_or_null("QuestWindow"):
		return

	var quest_window_scene = preload("res://scenes/windows/quest_window.tscn")
	var quest_window = quest_window_scene.instantiate()
	quest_window.name = "QuestWindow"
	add_child(quest_window)

	SignalBus.quest_log_opened.emit()
```

**Why:** Opens quest window with Q key. Can also add UI button later.

---

#### Step 13: Create Creature Selection Window for Turn-Ins

**File:** `scenes/windows/quest_creature_selector.tscn` (NEW SCENE)

**Create this scene structure:**
```
QuestCreatureSelector (PanelContainer)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleBar (HBoxContainer)
│       │   ├── Title (Label) - "Select Creatures for Quest"
│       │   └── CloseButton (Button) - "X"
│       ├── QuestInfo (Label)
│       ├── HSeparator
│       ├── CreatureGrid (GridContainer) - columns = 4
│       ├── HSeparator2
│       ├── SelectedInfo (Label) - "Selected: 0/1"
│       └── ButtonRow (HBoxContainer)
│           ├── CancelButton (Button) - "Cancel"
│           └── ConfirmButton (Button) - "Turn In"
```

**Configure:**
- QuestCreatureSelector: custom_minimum_size = (800, 600)
- CreatureGrid: columns = 4, separation = 10

**Attach script:** `scenes/windows/quest_creature_selector.gd`

---

#### Step 14: Create Creature Selector Script

**File:** `scenes/windows/quest_creature_selector.gd` (NEW FILE)

```gdscript
# scenes/windows/quest_creature_selector.gd
extends PanelContainer

@onready var title = $MarginContainer/VBoxContainer/TitleBar/Title
@onready var quest_info = $MarginContainer/VBoxContainer/QuestInfo
@onready var creature_grid = $MarginContainer/VBoxContainer/CreatureGrid
@onready var selected_info = $MarginContainer/VBoxContainer/SelectedInfo
@onready var cancel_button = $MarginContainer/VBoxContainer/ButtonRow/CancelButton
@onready var confirm_button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var close_button = $MarginContainer/VBoxContainer/TitleBar/CloseButton

var quest: QuestResource = null
var selected_creatures: Array[CreatureData] = []
var required_count: int = 0

func _ready():
	close_button.pressed.connect(close_window)
	cancel_button.pressed.connect(close_window)
	confirm_button.pressed.connect(_on_confirm_pressed)

	# Center on screen
	position = Vector2(
		(get_viewport_rect().size.x - size.x) / 2,
		(get_viewport_rect().size.y - size.y) / 2
	)

func setup(quest_resource: QuestResource):
	quest = quest_resource

	# Calculate total creatures needed
	required_count = 0
	for req in quest.requirements:
		required_count += req.quantity

	title.text = "Select Creatures: " + quest.quest_title
	quest_info.text = quest.get_requirements_summary()

	populate_creature_grid()
	update_selected_info()

func populate_creature_grid():
	# Clear existing
	for child in creature_grid.get_children():
		child.queue_free()

	# Add creature buttons
	if GameManager.player_data:
		for creature in GameManager.player_data.creatures:
			var button = create_creature_button(creature)
			creature_grid.add_child(button)

func create_creature_button(creature: CreatureData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 80)
	button.toggle_mode = true

	# Button text with creature info
	var species_name = GlobalEnums.Species.keys()[creature.species]
	button.text = "%s\n%s\nSTR:%d AGI:%d INT:%d" % [
		creature.creature_name,
		species_name,
		creature.strength,
		creature.agility,
		creature.intelligence
	]

	# Check if creature matches ANY requirement
	var matches_any = false
	for req in quest.requirements:
		if req.creature_matches(creature):
			matches_any = true
			break

	# Color code: Green if matches, Red if doesn't
	if matches_any:
		button.modulate = Color(0.8, 1.0, 0.8)  # Light green
	else:
		button.modulate = Color(1.0, 0.8, 0.8)  # Light red

	button.toggled.connect(func(pressed): _on_creature_toggled(creature, pressed))

	return button

func _on_creature_toggled(creature: CreatureData, pressed: bool):
	if pressed:
		if selected_creatures.size() < required_count:
			selected_creatures.append(creature)
		else:
			# Deselect if too many
			find_creature_button(creature).button_pressed = false
			return
	else:
		selected_creatures.erase(creature)

	update_selected_info()

func find_creature_button(creature: CreatureData) -> Button:
	for child in creature_grid.get_children():
		if child is Button:
			# Match by checking creature data (simple approach)
			if creature in selected_creatures:
				return child
	return null

func update_selected_info():
	selected_info.text = "Selected: %d/%d" % [selected_creatures.size(), required_count]
	confirm_button.disabled = selected_creatures.size() != required_count

func _on_confirm_pressed():
	# Validate creatures
	var validation = quest.validate_creatures(selected_creatures)

	if validation.valid:
		# Attempt turn in
		var success = GameManager.quest_manager.complete_quest(quest.quest_id, selected_creatures)
		if success:
			close_window()
		else:
			show_error("Failed to complete quest!")
	else:
		# Show what's missing
		var missing_text = "\n".join(validation.missing)
		show_error("Requirements not met:\n" + missing_text)

func show_error(message: String):
	# Future: Show error popup
	print("ERROR: ", message)

func close_window():
	queue_free()
```

**Why:** Allows player to select which creatures to turn in for quests. Visual feedback shows which creatures match requirements. Validates before submission.

---

#### Step 15: Connect Creature Selector to Quest Turn-In

**File:** `scenes/view/game_scene.gd`

**Add signal connection in `_ready()`:**

```gdscript
func _ready():
	# Existing connections...

	SignalBus.quest_turn_in_started.connect(_on_quest_turn_in_started)

# Add this function
func _on_quest_turn_in_started(quest: QuestResource):
	# Prevent multiple instances
	if get_node_or_null("QuestCreatureSelector"):
		return

	var selector_scene = preload("res://scenes/windows/quest_creature_selector.tscn")
	var selector = selector_scene.instantiate()
	selector.name = "QuestCreatureSelector"
	add_child(selector)
	selector.setup(quest)
```

**Why:** Opens creature selector when player clicks "Turn In" in quest window.

---

#### Step 16: Save/Load Quest Progress

**File:** `resources/save_game.gd`

**Add quest progress fields:**

```gdscript
# Existing fields...
@export var player_data: PlayerData
@export var current_week: int = 1
@export var metadata: Dictionary = {}

# Quest progress (NEW)
@export var active_quest_ids: Array[String] = []
@export var completed_quest_ids: Array[String] = []
```

**Why:** Persist quest progress across save/load.

---

#### Step 17: Update SaveManager for Quest Data

**File:** `core/save_manager.gd`

**Update `save_game()` function** to include quest data (around line 30-40):

```gdscript
func save_game() -> bool:
	var save_data = SaveGame.new()
	save_data.player_data = GameManager.player_data
	save_data.current_week = GameManager.current_week
	save_data.active_quest_ids = GameManager.quest_manager.active_quests  # NEW
	save_data.completed_quest_ids = GameManager.quest_manager.completed_quests  # NEW

	# ... rest of save logic
```

**Update `load_game()` function** to restore quest data (around line 60-70):

```gdscript
func load_game() -> bool:
	# ... existing load logic ...

	if save_data:
		GameManager.player_data = save_data.player_data
		GameManager.current_week = save_data.current_week

		# Restore quest progress (NEW)
		GameManager.quest_manager.active_quests = save_data.active_quest_ids
		GameManager.quest_manager.completed_quests = save_data.completed_quest_ids

		# ... rest of load logic
```

**Why:** Saves and restores quest progress. Player won't lose quest state on load.

---

#### Step 18: Update Architecture Documentation

**File:** `DEVELOPMENT_GUIDE.md`

**After completing implementation, add to "Completed Implementations" section:**

```markdown
### ✅ Quest System with Resource-Based Design
**Implemented complete quest system with multi-stage quest lines:**

**Features:**
- Resource-based quest definitions (QuestResource, QuestRequirement, QuestReward)
- QuestManager autoload for progression tracking
- Quest validation with stat and species requirements
- Quest chain with prerequisites
- Creature turn-in system with selection UI
- Save/load quest progress
- "The Collector's Needs" quest line (5 quests)
- Q key to open quest log

**Architecture:**
- **QuestRequirement**: Defines creature requirements (species, stats, quantity, tags)
- **QuestReward**: Gold, XP, special unlocks
- **QuestResource**: Complete quest definition with validation
- **QuestManager**: Quest progression, validation, completion
- **QuestWindow**: Quest log UI
- **QuestCreatureSelector**: Creature selection for turn-ins

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
- `core/managers/quest_manager.gd` (instance, not autoload)
- `scenes/windows/quest_window.tscn/gd`
- `scenes/windows/quest_creature_selector.tscn/gd`

**Signals Added:**
- `quest_accepted(quest)`
- `quest_completed(quest)`
- `quest_turn_in_failed(quest, missing)`
- `quest_turn_in_started(quest)`
- `quest_log_opened()`
- `quest_log_closed()`
- `creature_removed(creature)`

**Future Extensibility:**
- Tags system ready (required_tags array)
- Item rewards ready (items array)
- Easy to create new quests as .tres files
- Multi-part requirements supported
```

**And update "Current Architecture Summary":**

```markdown
**GameManager**
- Manages PlayerData (gold, creatures)
- Handles game initialization
- Controls week progression
- Contains `facility_manager` instance (FacilityManager)
- Contains `quest_manager` instance (QuestManager) (NEW)
```

**Why:** Keeps documentation current. QuestManager follows same pattern as FacilityManager (instance, not autoload).

---

### Testing the Quest System

Once implemented, test with these steps:

1. **Start new game**
   - Quest COL-01 should auto-accept
   - Check console for "Quest accepted: First Guardian"

2. **Press Q to open Quest Log**
   - Should see "First Guardian" in quest list
   - Requirements should show: "Scuttleguard - STR ≥ 15"
   - Rewards should show: "300 Gold"

3. **Generate qualifying creature**
   - Use F12 or shop to get/generate a Scuttleguard with STR ≥ 15
   - (Starter creatures might already qualify!)

4. **Turn in quest**
   - Click "Select Creatures" button
   - Creature selector opens
   - Green creatures match requirements, red don't
   - Select qualifying creature
   - Click "Turn In"
   - Creature removed, gold awarded
   - Quest COL-02 auto-accepts

5. **Test quest chain**
   - Complete COL-02 (Wind Dancer AGI ≥ 15)
   - Complete COL-03 (Any creature INT ≥ 12)
   - Complete COL-04 (2 creatures all stats ≥ 12)
   - Complete COL-05 (1 creature all stats ≥ 18)

6. **Test save/load**
   - Complete a quest
   - Press F5 to save
   - Close game
   - Reopen, press F9 to load
   - Quest progress should persist

---

### Future Enhancements

**Easy additions after base system:**
- Create .tres files for quests (visual editing in Godot)
- Add creature tags system
- Item rewards
- Quest notifications/popups
- Quest markers in world
- Radiant/repeatable quests
- Quest journal categories (Active, Completed, Failed)
- Time-limited quests
- Multi-stage quest objectives

---

## Completed Implementations

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
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

*This section is cleared after each implementation is complete. Completed work is documented in the "Completed Implementations" section below.*

---

### 🎯 Creature Tag System (Resource-Based)

**Overview**: Adding a flexible resource-based tag system where tags can belong to multiple categories (species, training, breeding). Tags are .tres files, making them easy to create and extend.

**✅ Code Review Improvements Applied:**
1. ✓ Added `silent` parameter to `add_tag()` to prevent signals during creature initialization
2. ✓ Clarified Step 5 integration point (before `return creature` at line 47)
3. ✓ Added error handling to EditorScript directory creation
4. ✓ Added error handling to `ResourceSaver.save()` calls with helpful print statements
5. ✓ Split Step 9 into 9a/9b/9c for clarity (@onready, code, scene)
6. ✓ **Performance optimized:** Added `training_tags` cache to avoid looping all tags
7. ✓ Cleaner type hint comments (removed Godot 4.x limitation notes)

**Godot Best Practices Followed:**
- ✓ Typed arrays: `Array[TagResource]`, `Array[GlobalEnums.TagCategory]`
- ✓ Static utility class pattern (no autoload needed)
- ✓ Lazy loading with `if all_tags.is_empty()` check
- ✓ **Cached lookups** for frequently accessed data (training tags)
- ✓ Signal-driven architecture via SignalBus
- ✓ Resource-based data for easy serialization
- ✓ Proper @onready node references
- ✓ Error code checking on I/O operations

**Performance Characteristics:**
- `auto_grant_training_tags()`: O(n) where n = training tag count (typically 4-10)
- `get_tag()`: O(1) dictionary lookup
- `has_tag()`: O(n) where n = creature's tag count (typically 3-8)
- Scales well to hundreds of total tags

**Architecture Design:**

```
GlobalEnums.TagCategory (enum):
├── SPECIES - Innate tags from species
├── TRAINING - Earned through activities
├── BREEDING - Inherited from parents
├── SPECIAL - Event/quest rewards
└── NEGATIVE - Debuffs/challenges

TagResource (defines a single tag)
├── tag_id: String (unique identifier)
├── tag_name: String (display name)
├── description: String (what this tag means)
├── categories: Array[GlobalEnums.TagCategory] (can be in multiple)
├── icon: Texture2D (future: visual icon)
├── color: Color (UI color coding)
└── training_requirement: Dictionary (for training tags)

CreatureData Enhancement (Simple Data Access):
├── tags: Array[TagResource] (all current tags)
└── Functions: has_tag(), get_tags_display() (simple queries only)

TagManager (Static Utility - Complex Operations):
├── all_tags: Dictionary (String -> TagResource, loaded once)
├── training_tags: Array[TagResource] (cached for performance)
├── species_tag_map: Dictionary (Species -> Array[String])
└── Functions:
    ├── load_tags(), get_tag() (tag loading/lookup)
    ├── add_tag(), remove_tag() (tag mutations with signals)
    ├── get_tags_by_category() (filtering logic)
    ├── get_species_tags() (species tag assignment)
    └── auto_grant_training_tags() (optimized with cache)
```

**Example Tags:**

- **"Armored"** (SPECIES, TRAINING)
  - Species: Scuttleguard starts with it
  - Training: Can be earned with STR ≥ 20

- **"Swift"** (SPECIES, TRAINING)
  - Species: Wind Dancer starts with it
  - Training: Can be earned with AGI ≥ 20

- **"Purebred"** (BREEDING)
  - Only from breeding system

- **"Legendary"** (SPECIAL)
  - Quest reward or special achievement

**Quest Integration:**
- QuestRequirement uses `required_tags: Array[String]` (tag IDs)
- Can require specific tag regardless of how creature obtained it
- Example: "Need 1 creature with 'Armored' tag" matches both Scuttleguards (species) and highly-trained creatures (training)

---

#### Step 1: Add TagCategory Enum to GlobalEnums

**File:** `core/global_enums.gd`

**Add after existing enums:**

```gdscript
# Tag categories (tags can belong to multiple)
enum TagCategory {
	SPECIES,   # Innate tags from species
	TRAINING,  # Earned through activities
	BREEDING,  # Inherited from parents
	SPECIAL,   # Event/quest rewards
	NEGATIVE   # Debuffs/challenges
}
```

**Why:** Type-safe tag categories. Makes it clear what categories exist. Easier to work with than strings.

---

#### Step 2: Create TagResource Class

**File:** `resources/tag_resource.gd` (NEW FILE)

```gdscript
# resources/tag_resource.gd
extends Resource
class_name TagResource

# Unique identifier for this tag
@export var tag_id: String = ""

# Display name shown to player
@export var tag_name: String = "Unnamed Tag"

# What this tag represents
@export_multiline var description: String = ""

# Categories this tag belongs to (can be multiple)
@export var categories: Array[GlobalEnums.TagCategory] = []

# Visual appearance (future)
@export var icon: Texture2D = null
@export var color: Color = Color.WHITE

# Training requirement (only for training tags)
# Structure:
# {
#   "type": "stat_threshold" | "all_stats_threshold" | "activity_count" | "has_tag",
#   "stat": "strength" | "agility" | "intelligence",
#   "threshold": int,
#   "prerequisite_tag": "tag_id"
# }
@export var training_requirement: Dictionary = {}

# Check if this tag is in a specific category
func is_category(category: GlobalEnums.TagCategory) -> bool:
	return category in categories

# Get formatted display string
func get_display_name() -> String:
	return tag_name

# Get color-coded display (for rich text)
func get_colored_display() -> String:
	var hex_color = color.to_html(false)
	return "[color=#%s]%s[/color]" % [hex_color, tag_name]
```

**Why:** Resource-based tags are flexible and extensible. Tags can belong to multiple categories. Clean data class - all complex logic moved to TagManager.

---

#### Step 3: Update CreatureData Resource

**File:** `resources/creature_data.gd`

**Add tag array and simple accessor functions:**

```gdscript
# Add after existing @export variables (around line 10-15)

# Tag system - stores TagResource references
@export var tags: Array[TagResource] = []

# Simple query: Check if creature has a specific tag (by tag_id)
func has_tag(tag_id: String) -> bool:
	for tag in tags:
		if tag and tag.tag_id == tag_id:
			return true
	return false

# Simple query: Get formatted tag string for UI display
func get_tags_display() -> String:
	if tags.is_empty():
		return "No tags"

	var tag_names: Array[String] = []
	for tag in tags:
		if tag:
			tag_names.append(tag.tag_name)

	return ", ".join(tag_names)

# Simple query: Get colored tag display (for rich text labels)
func get_tags_colored_display() -> String:
	if tags.is_empty():
		return "[color=gray]No tags[/color]"

	var tag_displays: Array[String] = []
	for tag in tags:
		if tag:
			tag_displays.append(tag.get_colored_display())

	return ", ".join(tag_displays)
```

**Why:** CreatureData stays simple with just the tag array and basic queries. All complex operations (add/remove/filter) handled by TagManager. Clean separation of concerns.

---

#### Step 4: Create TagManager Static Utility

**File:** `scripts/tag_manager.gd` (NEW FILE)

```gdscript
# scripts/tag_manager.gd
class_name TagManager

# All loaded tags [tag_id -> TagResource]
static var all_tags: Dictionary = {}  # String -> TagResource

# Cached training tags for performance (populated during load_all_tags)
static var training_tags: Array[TagResource] = []

# Species to tag mapping [Species -> Array of tag_id strings]
static var species_tag_map: Dictionary = {
	GlobalEnums.Species.SCUTTLEGUARD: ["armored", "defensive", "sturdy"],
	GlobalEnums.Species.SLIME: ["adaptable", "amorphous", "regenerative"],
	GlobalEnums.Species.WIND_DANCER: ["swift", "magical", "aerial"]
}

# ===== TAG LOADING & LOOKUP =====

# Load all tag resources from resources/tags/ folder
static func load_all_tags():
	all_tags.clear()
	training_tags.clear()

	var tags_dir = "res://resources/tags/"
	var dir = DirAccess.open(tags_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var tag_path = tags_dir + file_name
				var tag = load(tag_path) as TagResource
				if tag and tag.tag_id != "":
					all_tags[tag.tag_id] = tag

					# Cache training tags for fast lookup
					if tag.is_category(GlobalEnums.TagCategory.TRAINING):
						training_tags.append(tag)

					print("Loaded tag: ", tag.tag_name, " (", tag.tag_id, ")")
				else:
					print("Failed to load tag or missing tag_id: ", tag_path)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		print("Failed to open tags directory: ", tags_dir)

	print("TagManager: Total tags loaded: ", all_tags.size(), " (", training_tags.size(), " training tags)")

# Get a tag by ID
static func get_tag(tag_id: String) -> TagResource:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	return all_tags.get(tag_id, null)

# Get species tags for a creature species
static func get_species_tags(species: GlobalEnums.Species) -> Array[TagResource]:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	var tags: Array[TagResource] = []

	if not species_tag_map.has(species):
		return tags

	var tag_ids = species_tag_map[species]
	for tag_id in tag_ids:
		var tag = get_tag(tag_id)
		if tag:
			tags.append(tag)

	return tags

# ===== TAG MUTATIONS (with signals) =====

# Add a tag to a creature (handles validation and signals)
# silent: if true, don't emit signal (used during initialization)
static func add_tag(creature: CreatureData, tag: TagResource, silent: bool = false):
	if not tag or not creature:
		return

	# Don't add duplicates
	if tag in creature.tags:
		return

	creature.tags.append(tag)

	if not silent:
		SignalBus.creature_tag_added.emit(creature, tag.tag_id)
		print("Creature ", creature.creature_name, " gained tag: ", tag.tag_name)

# Remove a tag from a creature (handles signals)
static func remove_tag(creature: CreatureData, tag: TagResource):
	if not tag or not creature:
		return

	if tag in creature.tags:
		creature.tags.erase(tag)
		SignalBus.creature_tag_removed.emit(creature, tag.tag_id)
		print("Creature ", creature.creature_name, " lost tag: ", tag.tag_name)

# Remove tag by ID
static func remove_tag_by_id(creature: CreatureData, tag_id: String):
	for tag in creature.tags:
		if tag and tag.tag_id == tag_id:
			remove_tag(creature, tag)
			break

# ===== TAG QUERIES & FILTERING =====

# Get all tags a creature has in a specific category
static func get_creature_tags_by_category(creature: CreatureData, category: GlobalEnums.TagCategory) -> Array[TagResource]:
	var filtered: Array[TagResource] = []
	for tag in creature.tags:
		if tag and tag.is_category(category):
			filtered.append(tag)
	return filtered

# Get all tags in a specific category (from all loaded tags)
static func get_all_tags_by_category(category: GlobalEnums.TagCategory) -> Array[TagResource]:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	var filtered: Array[TagResource] = []
	for tag in all_tags.values():
		if tag and tag.is_category(category):
			filtered.append(tag)

	return filtered

# ===== TRAINING TAG LOGIC =====

# Check if creature qualifies for a training tag
static func check_training_qualification(creature: CreatureData, tag: TagResource) -> bool:
	if not tag.is_category(GlobalEnums.TagCategory.TRAINING):
		return false

	if tag.training_requirement.is_empty():
		return false

	var req_type = tag.training_requirement.get("type", "")

	match req_type:
		"stat_threshold":
			var stat_name = tag.training_requirement.get("stat", "")
			var threshold = tag.training_requirement.get("threshold", 0)
			var stat_value = creature.get(stat_name)
			return stat_value >= threshold

		"all_stats_threshold":
			var threshold = tag.training_requirement.get("threshold", 0)
			return (creature.strength >= threshold and
					creature.agility >= threshold and
					creature.intelligence >= threshold)

		"has_tag":
			var prereq_tag = tag.training_requirement.get("prerequisite_tag", "")
			return creature.has_tag(prereq_tag)

		"activity_count":
			# Future: Check activity history
			return false

	return false

# Check all training tags and auto-grant any creature qualifies for
static func auto_grant_training_tags(creature: CreatureData):
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	# Optimized: Only loop through training tags (cached during load)
	for tag in training_tags:
		# Skip if creature already has this tag
		if creature.has_tag(tag.tag_id):
			continue

		# Check if creature qualifies
		if check_training_qualification(creature, tag):
			add_tag(creature, tag)
```

**Why:** All complex tag operations centralized. Handles signals, validation, and business logic. Clear separation: simple queries on creature, complex operations through TagManager.

---

#### Step 5: Update CreatureGenerator to Assign Species Tags

**File:** `scripts/creature_generation.gd`

**In `generate_creature()` function, add species tags BEFORE the `return creature` statement (currently at line 47):**

**Before:**
```gdscript
	# ... stat generation code ends ...

	return creature
```

**After:**
```gdscript
	# ... stat generation code ends ...

	# Assign species-specific tags (NEW)
	var species_tags = TagManager.get_species_tags(species)
	for tag in species_tags:
		TagManager.add_tag(creature, tag, true)  # silent=true during creation

	return creature
```

**Why:** Automatically assigns species tags at creation using TagManager. Every creature starts with their species' innate tags. TagManager handles validation and signals.

---

#### Step 6: Add Training Tag Auto-Grant to Activities

**File:** `resources/activities/strength_training.gd` (and other activity files)

**After modifying stats (around line 15-20):**

```gdscript
func run_activity(creature: CreatureData) -> void:
	if not can_run(creature):
		return

	# Apply stat changes
	creature.strength += strength_gain

	# Auto-grant training tags if creature now qualifies (NEW)
	TagManager.auto_grant_training_tags(creature)

	print("Strength training completed: ", creature.creature_name, " gained ", strength_gain, " STR")
```

**Why:** After any stat change, check if creature now qualifies for training tags. TagManager handles all the logic and signals automatically.

---

#### Step 7: Add Tag Signals to SignalBus

**File:** `core/signal_bus.gd`

**Add in the Player & Resources section:**

```gdscript
# Player & Resources
signal gold_change_requested(amount: int)
signal gold_changed(new_amount: int)
signal creature_added(creature: CreatureData)
signal creature_removed(creature: CreatureData)
signal creature_stats_changed(creature: CreatureData)
signal creature_tag_added(creature: CreatureData, tag_id: String)  # NEW
signal creature_tag_removed(creature: CreatureData, tag_id: String)  # NEW
```

**Why:** Allows UI to react to tag changes. TagManager emits these signals when tags are added/removed. Can show notifications or update displays when creatures earn tags.

**Note:** No autoload registration needed! TagManager is a static utility class.

---

#### Step 8: Create Tag .tres Files with EditorScript

**File:** `scripts/generate_tags.gd` (NEW FILE)

```gdscript
# scripts/generate_tags.gd
@tool
extends EditorScript

func _run():
	# Create tags directory if it doesn't exist
	var dir = DirAccess.open("res://resources/")
	if dir:
		if not dir.dir_exists("tags"):
			var err = dir.make_dir("tags")
			if err != OK:
				print("ERROR: Could not create tags directory: ", err)
				return
	else:
		print("ERROR: Could not open resources directory")
		return

	# Generate species tags
	generate_tag_armored()
	generate_tag_defensive()
	generate_tag_sturdy()
	generate_tag_adaptable()
	generate_tag_amorphous()
	generate_tag_regenerative()
	generate_tag_swift()
	generate_tag_magical()
	generate_tag_aerial()

	# Generate training tags
	generate_tag_scholar()
	generate_tag_battle_hardened()
	generate_tag_agile_expert()
	generate_tag_disciplined()

	print("Tag generation complete!")

# Species tags

func generate_tag_armored():
	var tag = TagResource.new()
	tag.tag_id = "armored"
	tag.tag_name = "Armored"
	tag.description = "Natural armor plating provides excellent defense"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES, GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.7, 0.7, 0.7)  # Gray
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "strength",
		"threshold": 20
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/armored.tres")
	if err != OK:
		print("ERROR saving armored.tres: ", err)
	else:
		print("✓ Created armored.tres")

func generate_tag_defensive():
	var tag = TagResource.new()
	tag.tag_id = "defensive"
	tag.tag_name = "Defensive"
	tag.description = "Excels at protecting and guarding"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.4, 0.6, 0.8)  # Blue
	var err = ResourceSaver.save(tag, "res://resources/tags/defensive.tres")
	if err != OK:
		print("ERROR saving defensive.tres: ", err)
	else:
		print("✓ Created defensive.tres")

func generate_tag_sturdy():
	var tag = TagResource.new()
	tag.tag_id = "sturdy"
	tag.tag_name = "Sturdy"
	tag.description = "Robust constitution and resilience"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.5, 0.4)  # Brown
	var err = ResourceSaver.save(tag, "res://resources/tags/sturdy.tres")
	if err != OK:
		print("ERROR saving sturdy.tres: ", err)

# NOTE: Apply the same error handling pattern (check err != OK) to ALL remaining
# generate_tag_* functions below. Pattern shown in armored/defensive/sturdy above.

func generate_tag_adaptable():
	var tag = TagResource.new()
	tag.tag_id = "adaptable"
	tag.tag_name = "Adaptable"
	tag.description = "Can adjust to various situations"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.5, 0.8, 0.5)  # Light green
	ResourceSaver.save(tag, "res://resources/tags/adaptable.tres")

func generate_tag_amorphous():
	var tag = TagResource.new()
	tag.tag_id = "amorphous"
	tag.tag_name = "Amorphous"
	tag.description = "No fixed form, can reshape body"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.9, 0.6)  # Bright green
	ResourceSaver.save(tag, "res://resources/tags/amorphous.tres")

func generate_tag_regenerative():
	var tag = TagResource.new()
	tag.tag_id = "regenerative"
	tag.tag_name = "Regenerative"
	tag.description = "Natural healing and recovery abilities"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.3, 0.9, 0.3)  # Green
	ResourceSaver.save(tag, "res://resources/tags/regenerative.tres")

func generate_tag_swift():
	var tag = TagResource.new()
	tag.tag_id = "swift"
	tag.tag_name = "Swift"
	tag.description = "Exceptional speed and agility"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES, GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.9, 0.3)  # Yellow
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "agility",
		"threshold": 20
	}
	ResourceSaver.save(tag, "res://resources/tags/swift.tres")

func generate_tag_magical():
	var tag = TagResource.new()
	tag.tag_id = "magical"
	tag.tag_name = "Magical"
	tag.description = "Innate connection to magical energies"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.7, 0.4, 0.9)  # Purple
	ResourceSaver.save(tag, "res://resources/tags/magical.tres")

func generate_tag_aerial():
	var tag = TagResource.new()
	tag.tag_id = "aerial"
	tag.tag_name = "Aerial"
	tag.description = "Flight or aerial maneuvering capabilities"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.8, 1.0)  # Sky blue
	ResourceSaver.save(tag, "res://resources/tags/aerial.tres")

# Training tags

func generate_tag_scholar():
	var tag = TagResource.new()
	tag.tag_id = "scholar"
	tag.tag_name = "Scholar"
	tag.description = "Highly intelligent and learned"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.4, 0.4, 0.9)  # Deep blue
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "intelligence",
		"threshold": 15
	}
	ResourceSaver.save(tag, "res://resources/tags/scholar.tres")

func generate_tag_battle_hardened():
	var tag = TagResource.new()
	tag.tag_id = "battle_hardened"
	tag.tag_name = "Battle-Hardened"
	tag.description = "Experienced in combat and challenges"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.3, 0.3)  # Red
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "strength",
		"threshold": 18
	}
	ResourceSaver.save(tag, "res://resources/tags/battle_hardened.tres")

func generate_tag_agile_expert():
	var tag = TagResource.new()
	tag.tag_id = "agile_expert"
	tag.tag_name = "Agile Expert"
	tag.description = "Master of speed and dexterity"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.7, 0.2)  # Orange
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "agility",
		"threshold": 18
	}
	ResourceSaver.save(tag, "res://resources/tags/agile_expert.tres")

func generate_tag_disciplined():
	var tag = TagResource.new()
	tag.tag_id = "disciplined"
	tag.tag_name = "Disciplined"
	tag.description = "Well-rounded training across all areas"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.6, 0.6, 0.6)  # Gray
	tag.training_requirement = {
		"type": "all_stats_threshold",
		"threshold": 12
	}
	ResourceSaver.save(tag, "res://resources/tags/disciplined.tres")
```

**Why:** Programmatically generates all tag .tres files. Includes species tags (9) and training tags (4). Run once in Godot editor: File → Run → Run Script.

---

#### Step 9: Update Creature Stats Popup to Show Tags

**File:** `scenes/windows/creature_stats_popup.gd`

**Step 9a: Add @onready variable (at top with other labels):**

```gdscript
@onready var tags_label = $MarginContainer/VBoxContainer/TagsLabel
```

**Step 9b: Add tag display in setup() function (around line 30-40, after stat labels):**

```gdscript
func setup(creature: CreatureData):
	if not creature:
		return

	# Existing stat display code...
	name_label.text = creature.creature_name
	species_label.text = GlobalEnums.Species.keys()[creature.species]
	strength_label.text = "STR: %d" % creature.strength
	agility_label.text = "AGI: %d" % creature.agility
	intelligence_label.text = "INT: %d" % creature.intelligence

	# Add tags display (NEW)
	var tags_text = creature.get_tags_display()
	tags_label.text = "Tags: " + tags_text
```

**Step 9c: In the scene (creature_stats_popup.tscn), add a Label node:**

```
In the VBoxContainer, add after intelligence_label:
- TagsLabel (Label)
  - Text: "Tags: None"
  - Name: TagsLabel (important for @onready reference)
```

**Why:** Shows all creature tags in the stats popup. Players can see species tags, earned training tags, and future breeding tags. The @onready variable ensures safe node reference.

---

#### Step 10: Update Quest Requirement Tag Checking

Quest requirement tag checking already works! The `creature_matches()` function in `resources/quest_requirement.gd` already has the loop that checks `required_tags`. Since we updated CreatureData to use `has_tag(tag_id: String)`, the existing code will work:

```gdscript
# Already exists in quest_requirement.gd - no changes needed!
for required_tag in required_tags:
	if not creature.has_tag(required_tag):  # Works with our has_tag() function
		return false
```

The `get_description()` function also already displays required tags correctly.

**Why:** Quest system already integrated! Just need to add tag IDs to quest requirements.

---

#### Step 11: Add Tag Display to Creature Selector

**File:** `scenes/windows/quest_creature_selector.gd`

**Update `create_creature_button()` to show tags (around line 80-90):**

```gdscript
func create_creature_button(creature: CreatureData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 100)  # Taller to fit tags
	button.toggle_mode = true

	# Button text with creature info and tags
	var species_name = GlobalEnums.Species.keys()[creature.species]
	var tags_display = creature.get_tags_display()

	button.text = "%s\n%s\nSTR:%d AGI:%d INT:%d\n%s" % [
		creature.creature_name,
		species_name,
		creature.strength,
		creature.agility,
		creature.intelligence,
		tags_display
	]

	# ... rest of function
```

**Why:** Shows creature tags in quest turn-in UI. Helps players see which creatures meet tag requirements.

---

### Testing the Tag System

Once implemented, test with these steps:

1. **Start new game**
   - Generate creatures and check console for species tags
   - Scuttleguard should have: "Armored", "Defensive", "Sturdy"
   - Slime should have: "Adaptable", "Amorphous", "Regenerative"
   - Wind Dancer should have: "Swift", "Magical", "Aerial"

2. **View creature stats popup**
   - Click on creatures
   - Should see "Tags: Armored, Defensive, Sturdy" (etc)

3. **Train creatures**
   - Place creature in training facility
   - Advance week multiple times
   - Check if creature earns training tags:
     - STR ≥ 18 → "Battle-Hardened"
     - AGI ≥ 18 → "Agile Expert"
     - INT ≥ 15 → "Scholar"
     - All stats ≥ 12 → "Disciplined"

4. **Test tag-based quest** (if COL-06 implemented)
   - Complete COL-05
   - COL-06 should require "Armored" tag
   - Only Scuttleguards should match (they have "Armored" species tag)

5. **Test save/load**
   - Earn some training tags
   - Save game (F5)
   - Load game (F9)
   - Tags should persist

---

### Future Enhancements

**After base tag system:**
- Activity history tracking for activity_count training tags
- Breeding system with breeding tag inheritance
- Tag-based creature search/filter
- Tag tier system (Bronze/Silver/Gold versions of tags)
- Negative tags (debuffs or challenges)
- Tag combos (special bonuses when creature has specific tag combinations)
- Tag removal system (special items/activities to remove unwanted tags)

---

## Completed Implementations

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
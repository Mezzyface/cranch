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
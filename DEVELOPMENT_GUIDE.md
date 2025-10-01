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
gold_changed(amount) → [Not connected yet]
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
```

### System Overview

#### Autoload Order (Important!)
1. `GlobalEnums` - Game enumerations and constants
2. `SignalBus` - Central signal hub
3. `GameManager` - Game state management
4. `SaveManager` - Save/load operations

#### Core Systems

**GameManager**
- Manages PlayerData (gold, creatures)
- Handles game initialization
- Controls week progression
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

---

## Implementation Steps Section

### 🎯 Current Task: Facility Slot Locking System

**Goal:** Add locked/unlocked state to facility slots so players must pay gold to unlock additional slots.

**Design:**
- Slots 1-2: Unlocked by default
- Slots 3-4: Locked, require gold to unlock
- Locked slots show lock overlay with cost
- Click locked slot to unlock (if player has enough gold)
- Locked slots reject drag/drop and facility placement

---

#### Step 1: Add Locked State to FacilitySlot

**File:** `scenes/card/facility_slot.gd`

Add new exported properties at the top (after existing `@export` lines):

```gdscript
@export var is_locked: bool = false
@export var unlock_cost: int = 100
```

**Why:** Export allows setting locked state and cost per-slot in the Inspector.

---

#### Step 2: Add Locked Visual Overlay

**File:** `scenes/card/facility_slot.gd`

Add overlay nodes in `_ready()` function, after creating placeholder label and before creating drop zone:

```gdscript
func _ready():
	# ... existing placeholder label code ...

	# Create locked overlay if slot is locked
	if is_locked:
		_create_locked_overlay()

	# ... existing drop zone code ...
```

Add new function to create the locked overlay:

```gdscript
func _create_locked_overlay():
	# Create semi-transparent overlay
	var overlay = ColorRect.new()
	overlay.name = "LockedOverlay"
	overlay.color = Color(0, 0, 0, 0.7)  # Dark overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block interactions
	add_child(overlay)

	# Fill the entire slot
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)

	# Create lock icon (using a Label for now - can be replaced with texture later)
	var lock_icon = Label.new()
	lock_icon.text = "🔒"
	lock_icon.add_theme_font_size_override("font_size", 64)
	lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(lock_icon)
	lock_icon.set_anchors_preset(Control.PRESET_CENTER)

	# Create cost label
	var cost_label = Label.new()
	cost_label.text = "Unlock: %d gold" % unlock_cost
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(cost_label)
	cost_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cost_label.position.y = -40  # Offset from bottom

	# Make overlay clickable
	overlay.gui_input.connect(_on_locked_overlay_clicked)
```

**Why:** Visual feedback shows the slot is locked and displays the unlock cost.

---

#### Step 3: Add Unlock Signal to SignalBus

**File:** `core/signal_bus.gd`

Add new signal in the Facility section:

```gdscript
# Facility & Slot Management
signal facility_assigned(creature: CreatureData, facility: FacilityResource)
signal facility_unassigned(creature: CreatureData, facility: FacilityResource)
signal facility_slot_unlocked(slot_index: int, cost: int)  # NEW
```

**Why:** Allows other systems to react to slot unlocks (update UI, save state, etc).

---

#### Step 4: Implement Unlock Logic

**File:** `scenes/card/facility_slot.gd`

Add unlock handler function:

```gdscript
func _on_locked_overlay_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attempt_unlock()

func attempt_unlock():
	if not is_locked:
		return

	# Check if player has enough gold
	if not GameManager.player_data or GameManager.player_data.gold < unlock_cost:
		print("Not enough gold to unlock slot %d (need %d)" % [slot_index, unlock_cost])
		# TODO: Show feedback to player (shake effect, red flash, etc)
		return

	# Deduct gold
	GameManager.player_data.gold -= unlock_cost
	SignalBus.gold_changed.emit(GameManager.player_data.gold)

	# Unlock the slot
	is_locked = false

	# Remove locked overlay
	var overlay = get_node_or_null("LockedOverlay")
	if overlay:
		overlay.queue_free()

	# Emit signal
	SignalBus.facility_slot_unlocked.emit(slot_index, unlock_cost)

	print("Unlocked facility slot %d for %d gold" % [slot_index, unlock_cost])
```

**Why:** Handles the unlock transaction and updates the slot state.

---

#### Step 5: Prevent Interactions When Locked

**File:** `scenes/card/facility_slot.gd`

Update `place_facility()` to check locked state:

```gdscript
func place_facility(facility_card: FacilityCard) -> bool:
	# Check if slot is locked
	if is_locked:
		print("Cannot place facility - slot is locked")
		return false

	# ... rest of existing code ...
```

Update drop zone creation in `_ready()` to disable when locked:

```gdscript
func _ready():
	# ... existing code ...

	# Create drop zone (only if not locked)
	if not is_locked:
		var drop_zone = DragDropComponent.new()
		# ... rest of drop zone setup ...
```

**Why:** Prevents facility placement in locked slots via both code and drag/drop.

---

#### Step 6: Configure Slots in game_scene.tscn

**File:** `scenes/view/game_scene.tscn`

In Godot editor:

1. Select `FacilitySlot1` (first slot)
   - Inspector → Is Locked: `false`
   - Unlock Cost: (doesn't matter, unlocked)

2. Select `FacilitySlot2` (second slot)
   - Inspector → Is Locked: `false`
   - Unlock Cost: (doesn't matter, unlocked)

3. Select `FacilitySlot3` (third slot)
   - Inspector → Is Locked: `true`
   - Unlock Cost: `100`

4. Select `FacilitySlot4` (fourth slot)
   - Inspector → Is Locked: `true`
   - Unlock Cost: `150`

5. Save the scene

**Why:** Sets up the initial locked state for slots 3 and 4.

---

#### Step 7: Update _place_test_facility_in_slot to Use First Unlocked Slot

**File:** `scenes/view/game_scene.gd`

Update the function to find the first unlocked slot:

```gdscript
func _place_test_facility_in_slot():
	# Get first unlocked slot from scene tree
	var first_slot = null
	for child in get_children():
		if child is FacilitySlot and not child.is_locked:
			first_slot = child
			break

	if first_slot:
		# Create test facility card
		var training_facility = FacilityResource.new()
		# ... rest of existing code ...
```

**Why:** Ensures test facility is placed in an unlocked slot.

---

### Optional Enhancements (Can Add Later)

1. **Save/Load Unlock State:**
   - Add unlocked_slots array to PlayerData
   - Save which slots are unlocked on game save
   - Restore locked state on load

2. **Visual Feedback:**
   - Add shake effect when trying to unlock without gold
   - Add unlock animation (fade out overlay, particles)
   - Add hover effect on locked slots

3. **Audio:**
   - Play "unlock" sound effect
   - Play "error" sound when not enough gold

4. **UI Notifications:**
   - Show "Slot Unlocked!" message
   - Update gold display immediately

---

### Testing Checklist

After implementation:
- [ ] Slots 1-2 start unlocked, 3-4 start locked
- [ ] Locked slots show dark overlay with lock icon and cost
- [ ] Cannot drag facilities to locked slots
- [ ] Cannot drop creatures on locked slots
- [ ] Click locked slot attempts unlock
- [ ] Unlock fails if not enough gold (prints message)
- [ ] Unlock succeeds if enough gold (deducts cost, removes overlay)
- [ ] Unlocked slot accepts facilities normally
- [ ] Test facility places in first unlocked slot
- [ ] Gold amount updates after unlock

---

## Completed Implementations

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
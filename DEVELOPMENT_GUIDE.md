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

### 🎯 Current Task: Convert FacilitySlot to Scene

**Goal:** Convert FacilitySlot from a script-only class to a proper scene that can be placed manually in the editor while keeping all functionality.

---

#### Step 1: Create FacilitySlot Scene

**File:** `scenes/card/facility_slot.tscn`

1. In Godot editor, create a new scene: Scene → New Scene
2. Select "Other Node" and choose **Panel** as the root node
3. Name the root node: `FacilitySlot`
4. Attach the existing script: `res://scenes/card/facility_slot.gd`

**Scene Structure:**
```
FacilitySlot (Panel)
└── (Script creates PlaceholderLabel and DragDropComponent in _ready())
```

**Root Node Settings:**
- Custom Minimum Size: (320, 420)
- Layout → Container Sizing → Expand (to fill HBoxContainer)

5. Save the scene as `scenes/card/facility_slot.tscn`

**Why:** Creating a scene allows you to place FacilitySlots directly in game_scene.tscn instead of creating them programmatically.

---

#### Step 2: Update game_scene.tscn to Use FacilitySlot Scenes

**File:** `scenes/view/game_scene.tscn`

1. Open `game_scene.tscn` in the editor
2. Find the `FacilitySlotContainer` (HBoxContainer) node
3. Delete any existing FacilitySlot nodes if present
4. Right-click `FacilitySlotContainer` → "Instance Child Scene"
5. Select `scenes/card/facility_slot.tscn`
6. Repeat 2 more times (total 3 FacilitySlot instances)
7. Name them: `FacilitySlot1`, `FacilitySlot2`, `FacilitySlot3`

**Configure each slot:**
- Select `FacilitySlot1` → Inspector
  - Slot Index: `0`
  - Slot Name: `"Facility 1"`
- Select `FacilitySlot2` → Inspector
  - Slot Index: `1`
  - Slot Name: `"Facility 2"`
- Select `FacilitySlot3` → Inspector
  - Slot Index: `2`
  - Slot Name: `"Facility 3"`

8. Save the scene

**Why:** This removes the need for programmatic creation and allows visual editing of slots in the editor.

---

#### Step 3: Update game_scene.gd to Use Scene Slots

**File:** `scenes/view/game_scene.gd`

Remove the programmatic slot creation. Find `_create_facility_slots()` function (around line 270-292) and replace:

**OLD CODE:**
```gdscript
func _create_facility_slots():
	# Create container for facility slots
	var slot_container = HBoxContainer.new()
	slot_container.name = "FacilitySlotContainer"
	slot_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	slot_container.position = Vector2(50, -500)
	slot_container.add_theme_constant_override("separation", 20)
	add_child(slot_container)

	# Create 3 facility slots
	for i in range(3):
		var slot = FacilitySlot.new()
		slot.slot_index = i
		slot.slot_name = "Facility " + str(i + 1)
		slot.name = "FacilitySlot_" + str(i)
		slot_container.add_child(slot)

		# Connect signals
		slot.facility_placed.connect(_on_facility_placed)
		slot.facility_removed.connect(_on_facility_removed)

	# Place test facility in first slot
	_place_test_facility_in_slot()
```

**NEW CODE:**
```gdscript
func _create_facility_slots():
	# Slots now exist in the scene tree
	# Just connect their signals
	var slot_container = $FacilitySlotContainer
	for slot in slot_container.get_children():
		if slot is FacilitySlot:
			# Connect signals
			slot.facility_placed.connect(_on_facility_placed)
			slot.facility_removed.connect(_on_facility_removed)

	# Place test facility in first slot
	_place_test_facility_in_slot()
```

**Why:** Slots are now part of the scene, so we only need to connect signals instead of creating them.

---

#### Step 4: Remove FacilitySlot Preload (Optional Cleanup)

**File:** `scenes/view/game_scene.gd`

Remove the FacilitySlot preload at the top (around line 9):

**REMOVE:**
```gdscript
const FacilitySlot = preload("res://scenes/card/facility_slot.gd")
```

**Why:** We no longer instantiate FacilitySlot programmatically, so the preload isn't needed.

---

### Testing

After implementation:
- [ ] Open game_scene.tscn and see 3 FacilitySlot instances
- [ ] Can adjust slot properties in Inspector
- [ ] Run the game - slots appear at bottom
- [ ] Drag facility card to slot - works correctly
- [ ] Slots show placeholder text when empty
- [ ] All drag/drop functionality intact

---

**Previous task completed:** Creature Stats Popup & Bug Fixes
- Added creature stats popup with click detection
- Fixed facility activity execution
- Fixed creature duplication bug

---

## Completed Implementations

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
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

# Player & Resources
gold_changed(amount) → [Not connected yet]
creature_added(creature) → [Not connected yet]

# Game Progress
week_advanced(week) → [Not connected yet]

# UI Events
show_debug_popup_requested → [Not connected yet]
creature_stats_changed(creature) → [Not connected yet]
```

### System Overview

#### Autoload Order (Important!)
1. `GlobalEnums` - Game enumerations and constants
2. `SignalBus` - Central signal hub
3. `GameManager` - Game state management

#### Core Systems

**GameManager**
- Manages PlayerData (gold, creatures)
- Handles game initialization
- Controls week progression
- Emits state changes through SignalBus

**SignalBus**
- Central hub for all signals
- No logic, just signal definitions
- Enables decoupled communication

**PlayerData Resource**
- Contains: gold, creatures array
- Persistent data structure

**CreatureData Resource**
- Contains: name, species, strength, agility, intelligence
- Individual creature stats

---

## Implementation Steps Section

### Current Task: Debug Creature Dragging from Facility Cards

**Goal:** Identify why creatures on facility cards cannot be dragged even with drag controls added.

Looking at your implementation, I can see:
1. You've added the drag control to each creature sprite
2. You've set mouse_filter to IGNORE on containers
3. You've created the FacilityCreatureDrag script
4. But dragging still doesn't work

#### Potential Issues to Check:

**Issue 1: Z-order and Scene Tree Position**
The drag_control might be behind other elements or not receiving input due to scene tree order.

**Issue 2: The AnimatedSprite2D parent**
The drag_control is added as a child of AnimatedSprite2D, but AnimatedSprite2D nodes don't process mouse input by default.

**Issue 3: Mouse Filter on Wrong Elements**
Setting MOUSE_FILTER_IGNORE on containers might prevent the drag_control from receiving events.

#### Debugging Steps:

**Step 1: Check if drag_control is receiving events**
**File:** `scripts/facility_creature_drag.gd`

Add debug output to verify the control is getting mouse events:

```gdscript
func _ready():
	print("FacilityCreatureDrag ready for creature: ", creature_data.creature_name if creature_data else "unknown")
	mouse_entered.connect(func(): print("Mouse entered creature drag area"))

func _gui_input(event):
	if event is InputEventMouseButton:
		print("Mouse button event on creature: ", creature_data.creature_name if creature_data else "unknown")

func _get_drag_data(_position: Vector2):
	print("_get_drag_data called for creature: ", creature_data.creature_name if creature_data else "unknown")
	# ... rest of function
```

**Step 2: Fix the drag_control positioning**
**File:** `scenes/card/facility_card.gd`

Looking at your implementation, the drag_control is at position `(-30, -30)` which is outside the container bounds. Fix this:

```gdscript
func _add_creature_sprite(creature: CreatureData, slot_index: int):
	# ... existing code for sprite creation ...

	# Position the sprite in the slot container
	var slot_container = creature_slots.get_child(slot_index)

	# IMPORTANT: Make sure slot_container can pass events
	slot_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Change from IGNORE

	slot_container.add_child(sprite)
	sprite.position = Vector2(30, 30)  # Center in the 60x60 slot

	# Create drag control that covers the whole slot
	var drag_control = Control.new()
	drag_control.name = "DragControl"
	drag_control.custom_minimum_size = Vector2(60, 60)
	drag_control.position = Vector2(0, 0)  # Start at container origin, not negative!
	drag_control.mouse_filter = Control.MOUSE_FILTER_PASS

	# Make it visible for debugging
	drag_control.modulate = Color(1, 0, 0, 0.3)  # Red tint for debugging

	slot_container.add_child(drag_control)

	# Move drag control to front so it's above the sprite
	slot_container.move_child(drag_control, -1)

	# Set up the drag control
	var drag_script = FacilityCreatureDrag
	drag_control.set_script(drag_script)
	drag_control.creature_data = creature
	drag_control.facility_card = self
	drag_control.creature_sprite = sprite  # Add sprite reference
```

Also UPDATE in `setup_facility` when creating slots:

```gdscript
for i in range(facility.max_creatures):
	var slot_container = Control.new()
	slot_container.custom_minimum_size = Vector2(60, 60)
	slot_container.name = "Slot_" + str(i)
	slot_container.mouse_filter = Control.MOUSE_FILTER_PASS  # Change from IGNORE to PASS

	# ... rest of slot creation code ...
```

**Step 3: Verify the issue isn't with parent containers**
**File:** `scenes/card/facility_card.gd`

The problem might be that parent containers are still blocking. Check the entire chain:

```gdscript
func _ready():
	if facility_resource:
		setup_facility(facility_resource)

	# Make sure the creature slots container itself doesn't block
	if creature_slots:
		creature_slots.mouse_filter = Control.MOUSE_FILTER_PASS  # Not IGNORE!

	# Make this a drop target
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
```

**Why:** The issue is:
1. **Position `(-30, -30)`** puts the control outside the container's bounds
2. **MOUSE_FILTER_IGNORE on slot_container** prevents children from receiving events
3. The drag_control needs to be **within bounds** and its parent needs **MOUSE_FILTER_PASS**

**Key Points:**
- Control position `(0, 0)` starts at top-left of parent
- Negative positions put it outside parent bounds
- MOUSE_FILTER_IGNORE on parent blocks all child input
- MOUSE_FILTER_PASS allows events to reach children

---

### Testing Steps:
1. Try left-clicking on creatures - they should be draggable to facilities
2. If using Option B, middle-click on facility cards to move them between slots
3. Verify no input conflicts between creature and facility dragging
4. Check that creatures can be assigned to facilities normally

---

### Previous Implementation: FacilitySlot Scene and Script
**File:** `scenes/ui/facility_slot.gd` (Already implemented)

```gdscript
# scenes/ui/facility_slot.gd
extends Panel
class_name FacilitySlot

@export var slot_index: int = 0
@export var slot_name: String = "Facility Slot"

var current_facility_card: FacilityCard = null
var is_hover: bool = false

signal facility_placed(facility_card: FacilityCard, slot: FacilitySlot)
signal facility_removed(facility_card: FacilityCard, slot: FacilitySlot)

func _ready():
	custom_minimum_size = Vector2(320, 420)  # Slightly larger than facility cards
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Visual setup for empty slot
	_setup_empty_visual()

func _setup_empty_visual():
	# Add a dashed border or background to show it's an empty slot
	modulate = Color(0.5, 0.5, 0.5, 0.8)

	# Add placeholder text
	var label = Label.new()
	label.text = slot_name + "\n[Drop Facility Here]"
	label.add_theme_font_size_override("font_size", 14)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.name = "PlaceholderLabel"
	add_child(label)

func _on_mouse_entered():
	is_hover = true
	if not current_facility_card:
		modulate = Color(0.7, 0.7, 0.7, 0.9)

func _on_mouse_exited():
	is_hover = false
	if not current_facility_card:
		modulate = Color(0.5, 0.5, 0.5, 0.8)

func can_accept_facility(facility_card: FacilityCard) -> bool:
	# Can accept if empty or if we allow swapping
	return current_facility_card == null

func place_facility(facility_card: FacilityCard):
	# Remove from previous slot if it has one
	if facility_card.current_slot and facility_card.current_slot != self:
		facility_card.current_slot.remove_facility()

	# Place in this slot
	current_facility_card = facility_card
	facility_card.current_slot = self

	# Reparent the facility card to this slot
	if facility_card.get_parent():
		facility_card.get_parent().remove_child(facility_card)
	add_child(facility_card)
	facility_card.position = Vector2.ZERO

	# Hide placeholder
	if has_node("PlaceholderLabel"):
		$PlaceholderLabel.hide()

	# Reset modulate
	modulate = Color.WHITE

	facility_placed.emit(facility_card, self)

func remove_facility():
	if current_facility_card:
		var card = current_facility_card
		current_facility_card = null
		card.current_slot = null

		# Show placeholder again
		if has_node("PlaceholderLabel"):
			$PlaceholderLabel.show()

		_setup_empty_visual()
		facility_removed.emit(card, self)

func _can_drop_data(_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("facility_card") and can_accept_facility(data.facility_card)

func _drop_data(_position: Vector2, data) -> void:
	if data.has("facility_card"):
		place_facility(data.facility_card)
```

**Why:** Creates slots that can receive and hold facility cards via drag and drop.

#### Step 2: Update FacilityCard to be Draggable
**File:** `facility_card.gd`

**ADD** these variables at the top:

```gdscript
var current_slot: FacilitySlot = null
var is_being_dragged: bool = false
var drag_offset: Vector2
```

**ADD** drag functionality:

```gdscript
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right-click to start dragging the facility card itself
			accept_event()

func _can_drop_data(_position: Vector2, data) -> bool:
	# Facility cards accept creatures
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("creature") and can_accept_creature(data.creature)

func _get_drag_data(_position: Vector2):
	# Only allow dragging if not fixed in place
	if current_slot == null:
		return null

	# Create preview
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(150, 100)
	var label = Label.new()
	label.text = facility_resource.facility_name if facility_resource else "Facility"
	preview.add_child(label)
	set_drag_preview(preview)

	return {
		"facility_card": self
	}
```

**Why:** Makes facility cards draggable between slots with right-click.

#### Step 3: Create Facility Slot Container
**File:** `scenes/view/game_scene.gd`

**ADD** after `_create_week_display()`:

```gdscript
# Create facility slots
_create_facility_slots()
```

**ADD** new function:

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
		var slot = preload("res://scenes/ui/facility_slot.gd").new()
		slot.slot_index = i
		slot.slot_name = "Facility " + str(i + 1)
		slot.name = "FacilitySlot_" + str(i)
		slot_container.add_child(slot)

		# Connect signals
		slot.facility_placed.connect(_on_facility_placed)
		slot.facility_removed.connect(_on_facility_removed)

	# Place test facility in first slot
	_place_test_facility_in_slot()

func _place_test_facility_in_slot():
	# Get first slot
	var slot_container = $FacilitySlotContainer
	if slot_container and slot_container.get_child_count() > 0:
		var first_slot = slot_container.get_child(0)

		# Create test facility card
		var training_facility = FacilityResource.new()
		training_facility.facility_name = "Training Grounds"
		training_facility.description = "Train your creatures"
		training_facility.max_creatures = 2

		# Add a strength training activity
		var strength_activity = ActivityResource.new()
		strength_activity.activity_name = "Strength Training"
		strength_activity.description = "Gain +5 Strength"
		training_facility.activities.append(strength_activity)

		# Create and place card
		var card_scene = preload("res://scenes/card/facility_card.tscn")
		var card = card_scene.instantiate()
		card.facility_resource = training_facility
		card.add_to_group("facility_cards")

		first_slot.place_facility(card)

func _on_facility_placed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility placed: ", facility_card.facility_resource.facility_name, " in slot ", slot.slot_index)

func _on_facility_removed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility removed from slot ", slot.slot_index)
```

**Why:** Creates designated slots for facilities with visual feedback and placement logic.

#### Step 4: Remove Old Test Facility Spawning
**File:** `scenes/view/game_scene.gd`

**REMOVE** or comment out the old `_spawn_test_facilities()` function and its call in `_ready()`.

**Why:** Replaces direct facility spawning with the slot system.

---

### Testing Steps:
1. Run the game and see 3 empty facility slots at the bottom
2. First slot should have a test facility already placed
3. Right-click and drag facility cards between slots
4. Empty slots should show placeholder text
5. Drag creatures to facilities in slots - they should still work
6. Advance week to see training happen

---

### Benefits of This Approach

**No New Autoloads:**
- FacilityManager is a regular class, not a singleton
- GameManager creates and owns the instance
- Clean parent-child relationship

**Clear Ownership:**
- GameManager owns FacilityManager
- FacilityManager is destroyed when GameManager is destroyed
- No global state pollution

**Easy to Test:**
- Can create multiple FacilityManager instances for testing
- Can mock or replace FacilityManager easily
- Dependencies are explicit

**Flexible:**
- Can have different FacilityManagers for different game modes
- Can easily serialize/deserialize state
- Can clear and recreate as needed

### Alternative: Further Reducing Autoloads

If you want to reduce autoloads even more, consider these approaches:

#### Option 1: Make GameManager a Regular Node
Instead of an autoload, instantiate GameManager in your main scene:

```gdscript
# In game_scene.gd
@onready var game_manager = preload("res://core/game_manager.gd").new()

func _ready():
	add_child(game_manager)
	game_manager.initialize_new_game()
```

#### Option 2: Dependency Injection Pattern
Pass references instead of using singletons:

```gdscript
# facility_card.gd
var game_manager: Node  # Set by parent when creating

func assign_creature(creature: CreatureData, source_node: Node = null):
	if game_manager:
		game_manager.register_facility_assignment(creature, facility_resource)
```

#### Option 3: Scene-Based Management
Store game state in the scene tree:

```gdscript
# game_scene.gd becomes the main manager
var facility_assignments: Dictionary = {}

func register_facility_assignment(creature: CreatureData, facility: FacilityResource):
	# Handle it locally in the scene
```

**Current Minimal Autoload Setup:**
1. **GlobalEnums** - Shared constants (could be static class)
2. **SignalBus** - Event communication (could use scene signals)
3. **GameManager** - Core game state (could be scene node)
4. **SaveManager** - Save/Load (could be static functions)

---

### Testing the Previous Implementation:
1. Run the game
2. Click and hold on a creature to start dragging
3. Drag the creature over a facility card (it should highlight)
4. Drop the creature on the card
5. The creature should disappear and its name appear in the facility slot
6. Check console for activity execution messages

### What This Adds:
- Visual facility cards in the UI
- Drag and drop system for creature assignment
- Visual feedback during dragging
- Facility slots showing assigned creatures
- Automatic activity execution on assignment

---

## Completed Implementations

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

### File Structure
```
project/
├── core/
│   ├── game_manager.gd (Game logic)
│   ├── signal_bus.gd (Signal hub)
│   └── global_enums.gd (Constants)
├── resources/
│   ├── creature_data.gd
│   ├── player_data.gd
│   └── [other data classes]
├── scenes/
│   ├── view/ (Main scenes)
│   │   ├── main_menu.tscn/gd
│   │   └── game_scene.tscn/gd
│   └── windows/ (Popups)
│       └── debug_popup.tscn/gd
└── assets/
    └── sprites/creatures/
```

---

## Notes for Future Development

- SignalBus pattern keeps systems decoupled
- Always emit signals with relevant data
- Check if data exists before emitting
- Remember to disconnect signals when nodes are freed
- Use preload() for scenes that will be instantiated multiple times

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
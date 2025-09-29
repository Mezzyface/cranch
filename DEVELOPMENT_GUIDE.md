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

### Current Task: Facility Cards with Drag & Drop

**Goal:** Create UI facility cards that creatures can be dragged and dropped onto for assignment.

#### Step 1: Create FacilityCard Scene
**File:** `scenes/ui/facility_card.tscn` (NEW SCENE)

Create a new scene with this structure:
```
FacilityCard (Panel)
├── VBoxContainer
│   ├── NameLabel (Label)
│   ├── DescriptionLabel (Label)
│   ├── HSeparator
│   ├── ActivitiesLabel (Label - "Activities:")
│   ├── ActivitiesList (RichTextLabel)
│   └── CreatureSlots (HBoxContainer)
│       └── [Empty - will spawn slot indicators]
└── DropArea (Control - covers entire card)
```

Scene settings:
- FacilityCard: Custom minimum size (300, 400)
- DropArea: Mouse filter = MOUSE_FILTER_PASS, Anchor Full Rect

#### Step 2: Create FacilityCard Script
**File:** `scenes/ui/facility_card.gd` (NEW FILE)

```gdscript
# scenes/ui/facility_card.gd
extends Panel
class_name FacilityCard

@export var facility_resource: FacilityResource

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var activities_list: RichTextLabel = $VBoxContainer/ActivitiesList
@onready var creature_slots: HBoxContainer = $VBoxContainer/CreatureSlots
@onready var drop_area: Control = $DropArea

var assigned_creatures: Array[CreatureData] = []
var is_hover: bool = false

func _ready():
	if facility_resource:
		setup_facility(facility_resource)

	# Make this a drop target
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_facility(facility: FacilityResource):
	facility_resource = facility
	name_label.text = facility.facility_name
	description_label.text = facility.description

	# Display activities
	activities_list.clear()
	for activity in facility.activities:
		activities_list.append_text("• " + activity.activity_name + "\n")

	# Create creature slots
	for i in range(facility.max_creatures):
		var slot = Label.new()
		slot.text = "[Empty Slot]"
		slot.modulate = Color(0.5, 0.5, 0.5)
		creature_slots.add_child(slot)

func _on_mouse_entered():
	is_hover = true
	modulate = Color(1.1, 1.1, 1.1)  # Slight highlight on hover

func _on_mouse_exited():
	is_hover = false
	modulate = Color.WHITE

func can_accept_creature(creature: CreatureData) -> bool:
	return assigned_creatures.size() < facility_resource.max_creatures

func assign_creature(creature: CreatureData, source_node: Node = null):
	if can_accept_creature(creature):
		assigned_creatures.append(creature)
		update_slots()

		# Run activities on the creature
		facility_resource.run_all_activities(creature)

		# Remove the source creature from the world
		if source_node:
			source_node.queue_free()

		# Emit signal
		SignalBus.facility_assigned.emit(creature, facility_resource)
		return true
	return false

func update_slots():
	for i in range(creature_slots.get_child_count()):
		var slot = creature_slots.get_child(i)
		if i < assigned_creatures.size():
			slot.text = assigned_creatures[i].creature_name
			slot.modulate = Color.WHITE
		else:
			slot.text = "[Empty Slot]"
			slot.modulate = Color(0.5, 0.5, 0.5)

func _can_drop_data(_position: Vector2, data) -> bool:
	# Called by Godot's drag and drop system to check if we can accept the drop
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("creature") and can_accept_creature(data.creature)

func _drop_data(_position: Vector2, data) -> void:
	# Called when creature is dropped
	if data.has("creature") and data.has("source_node"):
		assign_creature(data.creature, data.source_node)

# Visual feedback during drag hover
func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		# Something is being dragged (might not be over us yet)
		pass
	elif what == NOTIFICATION_DRAG_END:
		# Drag operation ended
		modulate = Color.WHITE if not is_hover else Color(1.1, 1.1, 1.1)
```

**Why:** FacilityCard displays facility info and handles creature assignment through drag & drop.

#### Step 3: Add Drag Functionality to CreatureDisplay
**File:** `scenes/entities/creature_display.gd`

Since CreatureDisplay is a Node2D (not a Control), we need to add a Control child for drag detection. Add these variables at the top:
```gdscript
var creature_data: CreatureData  # Reference to this creature's data
var drag_area: Control  # Control node for handling drag
```

Add this to `_ready()`:
```gdscript
func _ready():
	# ... existing code ...

	# Create a Control node for drag detection
	drag_area = Control.new()
	drag_area.name = "DragArea"
	drag_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag_area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(drag_area)

	# Set the size to match the sprite
	drag_area.custom_minimum_size = Vector2(64, 64)  # Adjust to your sprite size
	drag_area.position = Vector2(-32, -32)  # Center it on the sprite

	# Connect drag functions
	drag_area.gui_input.connect(_on_drag_input)
```

Add these drag handling functions:
```gdscript
func _on_drag_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Start drag from the Control node
			drag_area.accept_event()

func set_creature_data(data: CreatureData):
	creature_data = data
	# Update visual based on creature species if needed
```

Add these to the drag_area Control (we'll do this via code):
```gdscript
func setup_drag_control():
	# Override the Control's drag functions
	drag_area.set_script(preload("res://scenes/entities/creature_drag_control.gd"))
	drag_area.creature_parent = self
	drag_area.creature_data = creature_data
```

**Alternative Simpler Approach:** Create a separate script for the drag Control:

**File:** `scenes/entities/creature_drag_control.gd` (NEW FILE)
```gdscript
# scenes/entities/creature_drag_control.gd
extends Control

var creature_parent: Node2D
var creature_data: CreatureData

func _can_drop_data(_position: Vector2, _data) -> bool:
	return false  # This is a drag source, not a drop target

func _get_drag_data(_position: Vector2):
	if not creature_data or not creature_parent:
		return null

	# Create a preview
	var preview = TextureRect.new()
	var sprite = creature_parent.get_node("AnimatedSprite2D")
	preview.texture = sprite.sprite_frames.get_frame(sprite.animation, sprite.frame)
	preview.modulate.a = 0.7
	preview.custom_minimum_size = Vector2(64, 64)
	set_drag_preview(preview)

	# Hide the original creature
	creature_parent.visible = false

	return {
		"creature": creature_data,
		"source_node": creature_parent
	}
```

Then update the main creature script to use this:
```gdscript
func _ready():
	# ... existing code ...

	# Add drag control
	var drag_script = preload("res://scenes/entities/creature_drag_control.gd")
	drag_area = Control.new()
	drag_area.name = "DragArea"
	drag_area.set_script(drag_script)
	drag_area.custom_minimum_size = Vector2(64, 64)
	drag_area.position = Vector2(-32, -32)
	add_child(drag_area)

	# Pass references
	drag_area.creature_parent = self
	drag_area.creature_data = creature_data
```

**Why:** Node2D doesn't have built-in drag support, so we add a Control child that handles the drag operations. The Control node provides the necessary drag and drop functions.

#### Step 4: Update GameScene to Spawn Facility Cards
**File:** `scenes/view/game_scene.gd`

Add after the creature spawning code:
```gdscript
func _ready():
	SignalBus.game_started.emit()
	SignalBus.player_data_initialized.connect(_on_player_data_ready)

	# Spawn test facility cards
	_spawn_test_facilities()

func _spawn_test_facilities():
	# Create a container for facility cards if it doesn't exist
	var facilities_container = Control.new()
	facilities_container.name = "FacilitiesContainer"
	facilities_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	facilities_container.position = Vector2(50, 50)
	add_child(facilities_container)

	# Create test facilities
	var training_facility = FacilityResource.new()
	training_facility.facility_name = "Training Grounds"
	training_facility.description = "Train your creatures"
	training_facility.max_creatures = 2

	# Add a strength training activity
	var strength_activity = ActivityResource.new()
	strength_activity.activity_name = "Strength Training"
	strength_activity.description = "Gain +5 Strength"
	training_facility.activities.append(strength_activity)

	# Spawn facility card
	var card_scene = preload("res://scenes/ui/facility_card.tscn")
	var card = card_scene.instantiate()
	card.facility_resource = training_facility
	card.add_to_group("facility_cards")
	facilities_container.add_child(card)
```

**Why:** Spawns facility cards in the game scene for testing.

#### Step 5: Update CreatureDisplay spawning to include data
**File:** `scenes/view/game_scene.gd`

Modify the creature spawning to pass creature data:
```gdscript
func _spawn_creature(creature_data: CreatureData):
	var creature_scene = preload("res://scenes/entities/creature_display.tscn")
	var creature_instance = creature_scene.instantiate()

	# Pass the creature data
	creature_instance.set_creature_data(creature_data)

	# Rest of spawning code...
	var spawn_x = randf_range(100, 1820)
	var spawn_y = randf_range(100, 980)
	creature_instance.position = Vector2(spawn_x, spawn_y)

	var container = $CreatureContainer
	if container:
		container.add_child(creature_instance)
```

**Why:** Ensures creatures have data references for the drag & drop system.

---

### Testing the Drag & Drop System:
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
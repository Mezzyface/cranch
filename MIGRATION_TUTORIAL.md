# Game Migration Tutorial: Simplified Vertical Slice

## Overview
This tutorial guides you through creating a simplified version of your creature management game from scratch, using the existing codebase as reference. The goal is to create a clean, minimal implementation with only the essential features.

## Target Features (Vertical Slice)
1. Main menu with "Start Game" button
2. Game scene with player stats display
3. Animated creature sprite that walks around
4. Training facility with drag-and-drop functionality
5. "Next Week" button that processes training and updates stats
6. Quest system with stat requirements
7. Ability to complete quests by turning in creatures

## Project Structure

### Phase 1: Project Setup and Core Architecture

#### Step 1: Create New Godot Project
1. Open Godot 4.3
2. Create new project: "CreatureGameSimplified"
3. Set up folder structure:
```
res://
├── scenes/
│   ├── main/
│   │   └── main.tscn
│   ├── ui/
│   │   ├── main_menu.tscn
│   │   └── game_ui.tscn
│   └── entities/
│       └── creature.tscn
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd
│   │   └── signal_bus.gd
│   ├── systems/
│   │   ├── creature_system.gd
│   │   ├── training_system.gd
│   │   └── quest_system.gd
│   ├── data/
│   │   └── creature_data.gd
│   └── ui/
│       ├── main_menu.gd
│       └── game_ui.gd
├── assets/
│   └── sprites/
└── data/
    └── creatures/
```

#### Step 2: Create Core Systems

**2.1 Signal Bus (Minimal Version)**
```gdscript
# scripts/core/signal_bus.gd
extends Node

# Core signals only
signal creature_stats_changed(creature_data: CreatureData)
signal training_completed(creature_data: CreatureData, stat_gains: Dictionary)
signal quest_completed(quest_id: String)
signal week_advanced(week: int)
```

**2.2 Game Manager (Simplified)**
```gdscript
# scripts/core/game_manager.gd
extends Node

var signal_bus: Node
var current_week: int = 1
var player_creatures: Array[CreatureData] = []

func _ready():
    signal_bus = preload("res://scripts/core/signal_bus.gd").new()
    add_child(signal_bus)

func start_new_game():
    current_week = 1
    player_creatures.clear()
    # Create starter creature
    var starter = create_starter_creature()
    player_creatures.append(starter)

func advance_week():
    current_week += 1
    signal_bus.week_advanced.emit(current_week)
```

### Phase 2: Data Structures

#### Step 3: Create Simplified Data Classes

**3.1 Creature Data (Reference: scripts/data/creature_data.gd)**
```gdscript
# scripts/data/creature_data.gd
extends Resource
class_name CreatureData

@export var id: String = ""
@export var creature_name: String = "Unnamed"
@export var species: String = "basic"

# Core stats only
@export var strength: int = 10
@export var intelligence: int = 10
@export var agility: int = 10

# Visual
@export var sprite_path: String = ""

func apply_training(stat_type: String, gain: int):
    match stat_type:
        "strength": strength += gain
        "intelligence": intelligence += gain
        "agility": agility += gain
```

### Phase 3: Core Systems Implementation

#### Step 4: Training System

**4.1 Training System (Reference: scripts/systems/training_system.gd)**
```gdscript
# scripts/systems/training_system.gd
extends Node
class_name TrainingSystem

var assigned_creatures: Dictionary = {} # facility_id -> CreatureData

func assign_creature(creature: CreatureData, facility_id: String):
    assigned_creatures[facility_id] = creature

func process_weekly_training():
    for facility_id in assigned_creatures:
        var creature = assigned_creatures[facility_id]
        var gains = calculate_gains(facility_id)
        apply_gains(creature, gains)

func calculate_gains(facility_id: String) -> Dictionary:
    # Simple gains based on facility type
    match facility_id:
        "training_facility":
            return {"strength": 5, "agility": 3}
        _:
            return {}
```

#### Step 5: Quest System

**5.1 Quest System (Reference: scripts/systems/quest_system.gd)**
```gdscript
# scripts/systems/quest_system.gd
extends Node
class_name QuestSystem

var active_quest: Dictionary = {}

func generate_quest():
    active_quest = {
        "id": "quest_001",
        "description": "I need a strong creature!",
        "requirements": {
            "strength": 20,
            "agility": 15
        },
        "reward": 100
    }

func check_requirements(creature: CreatureData) -> bool:
    for stat in active_quest.requirements:
        var required = active_quest.requirements[stat]
        var actual = creature.get(stat)
        if actual < required:
            return false
    return true

func complete_quest(creature: CreatureData):
    if check_requirements(creature):
        GameManager.signal_bus.quest_completed.emit(active_quest.id)
        # Remove creature from player collection
        # Add reward
```

### Phase 4: UI Implementation

#### Step 6: Main Menu

**6.1 Main Menu Scene Structure**
```
MainMenu (Control)
├── Background (ColorRect)
├── VBoxContainer
│   ├── Title (Label) - "Creature Training Game"
│   ├── StartButton (Button) - "Start Game"
│   └── QuitButton (Button) - "Quit"
```

**6.2 Main Menu Script**
```gdscript
# scripts/ui/main_menu.gd
extends Control

func _on_start_button_pressed():
    get_tree().change_scene_to_file("res://scenes/ui/game_ui.tscn")

func _on_quit_button_pressed():
    get_tree().quit()
```

#### Step 7: Game UI

**7.1 Game UI Scene Structure**
```
GameUI (Control)
├── TopBar (HBoxContainer)
│   ├── WeekLabel (Label) - "Week: 1"
│   └── NextWeekButton (Button) - "Next Week"
├── MainArea (HBoxContainer)
│   ├── CreatureArea (Control)
│   │   └── CreatureSprite (AnimatedSprite2D)
│   ├── FacilityArea (Control)
│   │   └── TrainingFacility (TextureRect)
│   └── StatsPanel (VBoxContainer)
│       ├── StrengthLabel
│       ├── IntelligenceLabel
│       └── AgilityLabel
└── QuestPanel (Panel)
    ├── QuestDescription (Label)
    └── TurnInButton (Button)
```

**7.2 Drag and Drop Implementation**
```gdscript
# Creature sprite script
extends AnimatedSprite2D

var can_drag = false
var dragging = false
var original_position: Vector2

func _ready():
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
    can_drag = true

func _on_mouse_exited():
    can_drag = false

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and can_drag:
                dragging = true
                original_position = global_position
            else:
                dragging = false
                check_drop_location()

    if event is InputEventMouseMotion and dragging:
        global_position = event.position

func check_drop_location():
    # Check if dropped on facility
    var facilities = get_tree().get_nodes_in_group("facilities")
    for facility in facilities:
        if facility.get_global_rect().has_point(global_position):
            # Assign to facility
            GameManager.training_system.assign_creature(creature_data, facility.name)
            return

    # Return to original position if not dropped on valid target
    global_position = original_position
```

### Phase 5: Animation and Polish

#### Step 8: Creature Animation

**8.1 Simple Walking Animation**
```gdscript
# Creature idle behavior
extends AnimatedSprite2D

var walk_target: Vector2
var walk_speed: float = 50.0

func _ready():
    # Set up simple animation
    sprite_frames = load("res://assets/sprites/creature_animations.tres")
    play("idle")

    # Random walk behavior
    _set_new_target()

func _process(delta):
    if not assigned_to_facility:
        _random_walk(delta)

func _random_walk(delta):
    var distance = global_position.distance_to(walk_target)
    if distance < 10:
        _set_new_target()
    else:
        var direction = (walk_target - global_position).normalized()
        global_position += direction * walk_speed * delta

        # Flip sprite based on direction
        if direction.x < 0:
            flip_h = true
        else:
            flip_h = false

        play("walk")

func _set_new_target():
    walk_target = Vector2(
        randf_range(50, 300),
        randf_range(200, 400)
    )
```

### Phase 6: Integration and Testing

#### Step 9: Wire Everything Together

**9.1 Game Flow**
1. Main.tscn loads → Shows MainMenu
2. Click Start → Load GameUI
3. GameUI initializes:
   - Creates GameManager singleton
   - Spawns starter creature
   - Shows initial quest
4. Player drags creature to facility
5. Click "Next Week":
   - Process training
   - Update stats
   - Update UI
6. Check quest completion
7. Allow turn-in if requirements met

**9.2 Autoload Setup**
In Project Settings → Autoload:
- GameManager: res://scripts/core/game_manager.gd

### Phase 7: Essential Features from Original

#### Step 10: Key Code to Reference

**From existing codebase, reference these files for implementation details:**

1. **Drag and Drop**:
   - `scripts/ui/creature_card_controller.gd` (lines 80-120)
   - `scripts/ui/facility_card.gd` (drop handling)

2. **Stats System**:
   - `scripts/data/creature_data.gd` (core data structure)
   - `scripts/systems/stat_system.gd` (stat calculations)

3. **Animation**:
   - `scripts/entities/creature_entity_controller.gd` (animation logic)

4. **Quest Requirements**:
   - `scripts/systems/quest_system.gd` (matching logic)

5. **UI Updates**:
   - `scripts/ui/overlay_menu_controller.gd` (UI refresh patterns)

## Testing Checklist

### Core Functionality Tests
- [ ] Main menu loads and Start button works
- [ ] Game scene loads with creature visible
- [ ] Creature animates and moves around
- [ ] Drag creature to facility works
- [ ] Next Week button processes training
- [ ] Stats update correctly
- [ ] Quest shows requirements
- [ ] Turn-in button enabled when requirements met
- [ ] Quest completion removes creature and gives reward

### Performance Targets
- Scene load: < 100ms
- Drag response: Immediate
- Week processing: < 50ms
- UI updates: < 16ms (60 FPS)

## Common Pitfalls to Avoid

1. **Over-engineering**: Start with hardcoded values, add configuration later
2. **Too many signals**: Use only essential signals listed above
3. **Complex save system**: Start with simple JSON, add complexity later
4. **Multiple creatures**: Focus on single creature first
5. **Complex animations**: Use simple 2-frame walk cycle initially

## Next Steps After Vertical Slice

Once the basic vertical slice works:
1. Add multiple creatures
2. Add more facility types
3. Implement proper save/load
4. Add more quest varieties
5. Implement resource management (gold, food)
6. Add shop system for buying creatures
7. Expand stat system

## Code Migration Priority

### Phase 1 (Essential):
- Signal bus pattern
- Basic creature data structure
- Drag and drop mechanics

### Phase 2 (Important):
- Stat calculation formulas
- Quest matching logic
- UI update patterns

### Phase 3 (Nice to Have):
- Animation state machines
- Save system
- Resource management

## Simplified Architecture Diagram

```
Main.tscn (Entry Point)
    ├── MainMenu.tscn
    └── GameUI.tscn
            ├── CreatureSprite (Draggable)
            ├── TrainingFacility (Drop Target)
            ├── StatsPanel (Display)
            ├── QuestPanel (Interactive)
            └── NextWeekButton (Processor)

GameManager (Singleton)
    ├── TrainingSystem
    ├── QuestSystem
    └── SignalBus

Data Flow:
1. User Action → GameManager
2. GameManager → System Processing
3. System → Signal Emission
4. UI → Signal Reception → Update Display
```

## Development Order

1. **Day 1**: Project setup, folder structure, core scripts
2. **Day 2**: Basic UI scenes, main menu, game scene structure
3. **Day 3**: Creature data, basic animation, display in scene
4. **Day 4**: Drag and drop implementation
5. **Day 5**: Training system, stat updates
6. **Day 6**: Quest system, requirements checking
7. **Day 7**: Polish, testing, bug fixes

## Final Notes

This simplified version removes:
- Complex save system
- Multiple systems (age, tags, species, etc.)
- Resource management beyond basic stats
- Complex UI overlays
- Event system
- Shop system (except quest turn-in)

Focus on getting the core loop working first. Each system should be under 100 lines of code. The entire project should be under 1000 lines total for the vertical slice.
# Simplified Implementation Guide

## Quick Start Implementation Order

### Day 1: Core Foundation (2-3 hours)

#### 1. Create Project Structure
```bash
# Create these folders in your new project
res://
├── scenes/
├── scripts/
├── assets/
└── data/
```

#### 2. Minimal Game Manager
```gdscript
# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_gold: int = 100
var player_creature: CreatureData

signal week_advanced(week: int)
signal stats_changed()

func _ready():
    # Create starter creature
    player_creature = CreatureData.new()
    player_creature.creature_name = "Starter"
    player_creature.strength = 10
    player_creature.agility = 10
    player_creature.intelligence = 10

func advance_week():
    current_week += 1
    process_training()
    week_advanced.emit(current_week)

func process_training():
    # If creature is in facility, apply gains
    if player_creature.assigned_facility:
        player_creature.strength += 5
        player_creature.agility += 3
        stats_changed.emit()
```

#### 3. Minimal Creature Data
```gdscript
# scripts/creature_data.gd
extends Resource
class_name CreatureData

@export var creature_name: String = "Unnamed"
@export var strength: int = 10
@export var agility: int = 10
@export var intelligence: int = 10
@export var assigned_facility: String = ""
```

### Day 2: UI Scenes (2-3 hours)

#### 1. Main Menu (scenes/main_menu.tscn)
```
Control (full_rect)
└── CenterContainer (full_rect)
    └── VBoxContainer
        ├── Label (text: "Creature Game")
        └── Button (text: "Start Game")
```

Script:
```gdscript
# scripts/main_menu.gd
extends Control

func _on_button_pressed():
    get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
```

#### 2. Game Scene (scenes/game_scene.tscn)
```
Control (full_rect)
├── TopBar (HBoxContainer)
│   ├── WeekLabel
│   └── NextWeekButton
├── MainArea (HSplitContainer)
│   ├── CreatureArea (Panel)
│   │   └── Creature (TextureRect)
│   ├── FacilityArea (Panel)
│   │   └── TrainingFacility (TextureRect)
│   └── StatsPanel (VBoxContainer)
│       ├── NameLabel
│       ├── StrLabel
│       ├── AgiLabel
│       └── IntLabel
└── QuestPanel (Panel)
    ├── QuestLabel
    └── TurnInButton
```

### Day 3: Drag and Drop (3-4 hours)

#### 1. Draggable Creature
```gdscript
# scripts/creature_sprite.gd
extends TextureRect

var dragging = false
var drag_offset = Vector2.ZERO

func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragging = true
                drag_offset = global_position - event.global_position
            else:
                dragging = false
                check_drop()

    elif event is InputEventMouseMotion and dragging:
        global_position = event.global_position + drag_offset

func check_drop():
    # Check if over facility
    var facility = get_node("../../FacilityArea/TrainingFacility")
    if facility.get_global_rect().has_point(global_position):
        GameManager.player_creature.assigned_facility = "training"
        # Snap to facility
        global_position = facility.global_position + Vector2(20, 20)
```

#### 2. Facility Drop Zone
```gdscript
# scripts/facility.gd
extends TextureRect

func _ready():
    # Visual indicator
    texture = preload("res://assets/facility.png")

func has_creature() -> bool:
    return GameManager.player_creature.assigned_facility == "training"
```

### Day 4: Animation (2 hours)

#### 1. Simple Walk Animation
```gdscript
# Add to creature_sprite.gd
var target_position: Vector2
var is_walking: bool = false

func _ready():
    # Set random walk target every 3 seconds
    var timer = Timer.new()
    timer.wait_time = 3.0
    timer.timeout.connect(_set_new_target)
    add_child(timer)
    timer.start()

func _process(delta):
    if not dragging and not GameManager.player_creature.assigned_facility:
        if is_walking:
            var dir = (target_position - position).normalized()
            position += dir * 50 * delta

            if position.distance_to(target_position) < 10:
                is_walking = false

func _set_new_target():
    if not dragging and not GameManager.player_creature.assigned_facility:
        target_position = Vector2(
            randf_range(50, 300),
            randf_range(50, 200)
        )
        is_walking = true
```

### Day 5: Stats & Training (2 hours)

#### 1. Next Week Processing
```gdscript
# scripts/game_scene.gd
extends Control

@onready var week_label = $TopBar/WeekLabel
@onready var str_label = $MainArea/StatsPanel/StrLabel
@onready var agi_label = $MainArea/StatsPanel/AgiLabel
@onready var int_label = $MainArea/StatsPanel/IntLabel

func _ready():
    GameManager.week_advanced.connect(_on_week_advanced)
    GameManager.stats_changed.connect(_update_stats)
    _update_stats()

func _on_next_week_pressed():
    GameManager.advance_week()

func _on_week_advanced(week: int):
    week_label.text = "Week: " + str(week)

func _update_stats():
    var c = GameManager.player_creature
    str_label.text = "STR: " + str(c.strength)
    agi_label.text = "AGI: " + str(c.agility)
    int_label.text = "INT: " + str(c.intelligence)
```

### Day 6: Quest System (3 hours)

#### 1. Simple Quest Manager
```gdscript
# scripts/quest_manager.gd
extends Node

var current_quest: Dictionary = {
    "description": "I need a strong warrior!",
    "requirements": {"strength": 20, "agility": 15},
    "reward": 500
}

func can_complete(creature: CreatureData) -> bool:
    return (creature.strength >= current_quest.requirements.strength
            and creature.agility >= current_quest.requirements.agility)

func complete_quest():
    if can_complete(GameManager.player_creature):
        GameManager.player_gold += current_quest.reward
        generate_new_quest()
        return true
    return false

func generate_new_quest():
    current_quest = {
        "description": "Find me an agile scout!",
        "requirements": {
            "strength": 15,
            "agility": 25
        },
        "reward": 750
    }
```

#### 2. Quest UI
```gdscript
# Add to game_scene.gd
@onready var quest_label = $QuestPanel/QuestLabel
@onready var turn_in_btn = $QuestPanel/TurnInButton

func _ready():
    # Previous code...
    _update_quest()

func _update_quest():
    var quest = QuestManager.current_quest
    quest_label.text = quest.description + "\n"
    quest_label.text += "Needs: STR %d, AGI %d" % [
        quest.requirements.strength,
        quest.requirements.agility
    ]

    turn_in_btn.disabled = not QuestManager.can_complete(GameManager.player_creature)

func _on_turn_in_pressed():
    if QuestManager.complete_quest():
        # Show success message
        print("Quest completed! Gold: ", GameManager.player_gold)
        _update_quest()
```

## Complete Minimal Project Files

### Project.godot
```ini
[application]
config/name="Creature Training Simplified"
run/main_scene="res://scenes/main_menu.tscn"

[autoload]
GameManager="*res://scripts/game_manager.gd"
QuestManager="*res://scripts/quest_manager.gd"

[display]
window/size/viewport_width=800
window/size/viewport_height=600
```

### File Checklist
```
✓ scenes/main_menu.tscn
✓ scenes/game_scene.tscn
✓ scripts/game_manager.gd
✓ scripts/creature_data.gd
✓ scripts/main_menu.gd
✓ scripts/game_scene.gd
✓ scripts/creature_sprite.gd
✓ scripts/facility.gd
✓ scripts/quest_manager.gd
✓ assets/creature.png (64x64 sprite)
✓ assets/facility.png (128x128 sprite)
```

## Testing Your Vertical Slice

### Manual Test Flow:
1. Run project → Main menu appears
2. Click "Start Game" → Game scene loads
3. See creature moving around randomly
4. Drag creature to training facility
5. Click "Next Week" → Stats increase
6. Check if quest requirements met
7. Click "Turn In" when enabled → Get reward

### Success Criteria:
- [ ] Game launches without errors
- [ ] Can transition from menu to game
- [ ] Creature visible and animated
- [ ] Drag and drop works
- [ ] Stats update on next week
- [ ] Quest shows requirements
- [ ] Can complete quest when requirements met

## Common Issues & Solutions

### Issue: Creature doesn't drag
**Solution**: Make sure mouse_filter is set to MOUSE_FILTER_STOP on the TextureRect

### Issue: Stats don't update
**Solution**: Check signal connections and ensure GameManager is autoloaded

### Issue: Drop doesn't work
**Solution**: Verify global_position calculations and rect overlap detection

### Issue: Animation stutters
**Solution**: Use _physics_process instead of _process for movement

## Total Line Count Estimate

- game_manager.gd: ~40 lines
- creature_data.gd: ~10 lines
- main_menu.gd: ~5 lines
- game_scene.gd: ~50 lines
- creature_sprite.gd: ~60 lines
- facility.gd: ~15 lines
- quest_manager.gd: ~30 lines

**Total: ~210 lines of code**

## Next Steps After Vertical Slice Works

1. Add save/load (50 lines)
2. Multiple creatures (100 lines)
3. More facilities (50 lines)
4. Shop system (100 lines)
5. Better animations (50 lines)
6. Sound effects (20 lines)
7. Polish UI (100 lines)

This keeps your codebase under 700 lines while having a fully functional game!
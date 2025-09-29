# Key Code References for Migration

## 1. Drag and Drop Implementation

### From creature_card_controller.gd
```gdscript
# Drag detection and handling
func _gui_input(event: InputEvent) -> void:
    if not _creature_data:
        return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _start_drag()
            else:
                _end_drag()

# Drag preview creation
func _make_custom_tooltip(for_text: String) -> Object:
    if _is_dragging:
        var preview = ColorRect.new()
        preview.custom_minimum_size = Vector2(100, 120)
        preview.color = Color(0.5, 0.5, 0.5, 0.8)
        return preview
    return null
```

### From facility_card.gd
```gdscript
# Drop handling
func _can_drop_data(position: Vector2, data: Variant) -> bool:
    if not data is Dictionary:
        return false
    return data.has("creature_data")

func _drop_data(position: Vector2, data: Variant) -> void:
    if data.has("creature_data"):
        var creature_data = data["creature_data"]
        _assign_creature(creature_data)
```

## 2. Animation System

### From creature_entity_controller.gd
```gdscript
# Simple animation state management
func setup_animation():
    if sprite:
        sprite.sprite_frames = load("res://assets/sprites/creature_animations.tres")
        sprite.play("idle")

# Movement with animation
func move_to_position(target: Vector2, delta: float):
    var direction = (target - global_position).normalized()
    global_position += direction * move_speed * delta

    # Flip sprite based on direction
    if sprite:
        sprite.flip_h = direction.x < 0

        if direction.length() > 0.1:
            sprite.play("walk")
        else:
            sprite.play("idle")
```

## 3. Stats System

### From creature_data.gd - Core Stats
```gdscript
# Base stats structure
@export var base_stats: Dictionary = {
    "strength": 10,
    "intelligence": 10,
    "agility": 10,
    "endurance": 10
}

# Stat modification
func modify_stat(stat_name: String, value: int) -> void:
    if stat_name in base_stats:
        base_stats[stat_name] += value
        stats_changed.emit()
```

### From training_system.gd - Training Logic
```gdscript
# Calculate training gains
func calculate_training_gains(creature: CreatureData, facility: FacilityResource) -> Dictionary:
    var gains = {}

    for activity in facility.supported_activities:
        if activity.stat_modifier:
            gains[activity.affected_stat] = activity.modifier_value

    return gains

# Apply training
func apply_training(creature: CreatureData, gains: Dictionary) -> void:
    for stat in gains:
        creature.modify_stat(stat, gains[stat])

    GameCore.get_signal_bus().training_completed.emit(creature, gains)
```

## 4. Quest System

### From quest_system.gd - Quest Matching
```gdscript
# Check if creature meets requirements
func check_quest_requirements(quest: Dictionary, creature: CreatureData) -> bool:
    for requirement in quest.requirements:
        var stat_value = creature.get_stat(requirement.stat)
        if stat_value < requirement.min_value:
            return false
    return true

# Complete quest
func complete_quest(quest_id: String, creature: CreatureData) -> void:
    var quest = active_quests[quest_id]
    if check_quest_requirements(quest, creature):
        # Remove creature from collection
        GameCore.get_system("collection").remove_creature(creature)

        # Give rewards
        GameCore.get_system("resource").add_gold(quest.reward_gold)

        # Emit completion signal
        GameCore.get_signal_bus().quest_completed.emit(quest_id)

        # Remove quest
        active_quests.erase(quest_id)
```

## 5. UI Update Pattern

### From overlay_menu_controller.gd
```gdscript
# Connect to signals for UI updates
func _ready():
    var bus = GameCore.get_signal_bus()
    bus.creature_stats_changed.connect(_on_creature_stats_changed)
    bus.week_advanced.connect(_on_week_advanced)
    bus.gold_changed.connect(_on_gold_changed)

# Update UI elements
func _on_creature_stats_changed(creature: CreatureData):
    if stats_panel:
        stats_panel.get_node("StrengthLabel").text = "STR: " + str(creature.strength)
        stats_panel.get_node("AgilityLabel").text = "AGI: " + str(creature.agility)
        stats_panel.get_node("IntelligenceLabel").text = "INT: " + str(creature.intelligence)

func _on_week_advanced(week: int):
    if week_label:
        week_label.text = "Week " + str(week)
```

## 6. Week Processing

### From weekly_update_orchestrator.gd
```gdscript
# Process all weekly updates
func advance_week() -> void:
    var week = GameCore.get_system("time").current_week

    # Process in order
    _process_training()
    _process_facility_income()
    _update_creature_stats()
    _check_quest_timers()

    # Emit completion
    GameCore.get_signal_bus().week_advanced.emit(week)

func _process_training():
    var training_system = GameCore.get_system("training")
    var facility_system = GameCore.get_system("facility")

    for assignment in facility_system.get_all_assignments():
        var gains = training_system.calculate_gains(assignment)
        training_system.apply_gains(assignment.creature, gains)
```

## 7. Simple Creature Generator

### Minimal creature creation
```gdscript
# From creature_generator.gd - Simplified version
func generate_starter_creature() -> CreatureData:
    var creature = CreatureData.new()
    creature.id = "starter_" + str(Time.get_unix_time_from_system())
    creature.creature_name = "Fluffy"
    creature.species = "basic_creature"

    # Random base stats
    creature.strength = randi_range(8, 12)
    creature.agility = randi_range(8, 12)
    creature.intelligence = randi_range(8, 12)

    creature.sprite_path = "res://assets/sprites/creatures/basic.png"

    return creature
```

## 8. Signal Bus Pattern

### From signal_bus.gd - Minimal signals needed
```gdscript
extends Node

# Core gameplay signals
signal creature_acquired(creature: CreatureData)
signal creature_removed(creature: CreatureData)
signal creature_stats_changed(creature: CreatureData)

# Training signals
signal creature_assigned_to_facility(creature: CreatureData, facility_id: String)
signal training_completed(creature: CreatureData, gains: Dictionary)

# Quest signals
signal quest_available(quest: Dictionary)
signal quest_completed(quest_id: String)
signal quest_requirements_met(quest_id: String)

# Time signals
signal week_advanced(week: int)

# UI signals
signal ui_refresh_needed()
```

## 9. Facility Drop Zone

### Simple facility implementation
```gdscript
# Facility as drop target
extends TextureRect

@export var facility_id: String = "training_facility"
@export var facility_name: String = "Training Grounds"

var assigned_creature: CreatureData = null

func _can_drop_data(position: Vector2, data: Variant) -> bool:
    if not data is Dictionary:
        return false
    if not data.has("creature_data"):
        return false
    # Only accept if no creature assigned
    return assigned_creature == null

func _drop_data(position: Vector2, data: Variant) -> void:
    var creature = data["creature_data"]
    assign_creature(creature)

func assign_creature(creature: CreatureData):
    assigned_creature = creature
    GameCore.get_signal_bus().creature_assigned_to_facility.emit(creature, facility_id)
    update_display()

func update_display():
    # Show creature portrait or indicator
    if assigned_creature:
        modulate = Color(0.8, 1.0, 0.8)  # Green tint when occupied
    else:
        modulate = Color.WHITE
```

## 10. Quest Popup

### Simple quest display
```gdscript
# Quest popup controller
extends Panel

var current_quest: Dictionary = {}

func show_quest(quest: Dictionary):
    current_quest = quest

    $VBox/Description.text = quest.description
    $VBox/Requirements.text = format_requirements(quest.requirements)
    $VBox/Reward.text = "Reward: %d gold" % quest.reward

    $VBox/TurnInButton.disabled = true
    visible = true

func format_requirements(reqs: Dictionary) -> String:
    var text = "Requirements:\n"
    for stat in reqs:
        text += "- %s: %d\n" % [stat.capitalize(), reqs[stat]]
    return text

func check_creature(creature: CreatureData):
    var meets_reqs = true
    for stat in current_quest.requirements:
        if creature.get(stat) < current_quest.requirements[stat]:
            meets_reqs = false
            break

    $VBox/TurnInButton.disabled = not meets_reqs

func _on_turn_in_pressed():
    # Turn in the selected creature
    GameCore.get_system("quest").complete_quest(current_quest.id)
    hide()
```
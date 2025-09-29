# SignalBus Implementation Guide

## Overview
This guide shows how to implement a centralized SignalBus pattern for your Godot game, building on top of the existing initialization system.

## Why Use a SignalBus?

### Benefits:
- **Decoupling**: GameManager doesn't need to know about UI components
- **Organization**: All signals defined in one place
- **Scalability**: Easy to add new signals and connections
- **Debugging**: Can monitor all game events from one location

### Architecture:
```
[GameManager] --emits--> [SignalBus] <--connects-- [UI Components]
     |                        ^                           |
     |                        |                           |
     +-- No direct connection needed between systems -----+
```

## Implementation Steps

### Step 1: Set Up the SignalBus
**File:** `core/signal_bus.gd`

```gdscript
# SignalBus - Central hub for all game signals
extends Node

# Game Flow Signals
signal game_started()
signal player_data_initialized()
signal week_advanced(week: int)

# Player & Resource Signals
signal gold_changed(new_amount: int)
signal creature_added(creature: CreatureData)
signal creature_stats_changed(creature: CreatureData)

# UI Signals
signal show_debug_popup_requested()
signal show_creature_details_requested(creature: CreatureData)
signal popup_closed(popup_name: String)

# Activity & Training Signals
signal training_started(creature: CreatureData, facility: Resource)
signal training_completed(creature: CreatureData)
signal activity_completed(creature: CreatureData, activity: Resource)
```

### Step 2: Add SignalBus to Autoload
**File:** `project.godot`

In the [autoload] section, add SignalBus BEFORE GameManager:
```ini
[autoload]

GlobalEnums="*res://core/global_enums.gd"
SignalBus="*res://core/signal_bus.gd"
GameManager="*res://core/game_manager.gd"
```

**Important:** Order matters! SignalBus must load before GameManager.

### Step 3: Update GameManager to Use SignalBus
**File:** `core/game_manager.gd`

Remove local signals and use SignalBus instead:

```gdscript
# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_data: PlayerData

# Remove these local signals:
# signal week_advanced(week: int)
# signal stats_changed()
# signal player_data_initialized()

func _ready():
	pass

func initialize_new_game():
	# Create player data container
	player_data = PlayerData.new()
	player_data.gold = 100

	# Create starter creature with proper species
	var starter_creature = CreatureData.new()
	starter_creature.creature_name = "Scuttle"
	starter_creature.species = GlobalEnums.Species.SCUTTLEGUARD
	starter_creature.strength = 10
	starter_creature.agility = 8
	starter_creature.intelligence = 6

	# Add to player's collection
	player_data.creatures.append(starter_creature)

	# Use SignalBus instead of local signals
	SignalBus.player_data_initialized.emit()
	SignalBus.creature_added.emit(starter_creature)
	SignalBus.gold_changed.emit(player_data.gold)

func advance_week():
	current_week += 1
	SignalBus.week_advanced.emit(current_week)

func update_creature_stats(creature: CreatureData, strength_delta: int, agility_delta: int, intelligence_delta: int):
	creature.strength += strength_delta
	creature.agility += agility_delta
	creature.intelligence += intelligence_delta
	SignalBus.creature_stats_changed.emit(creature)

func update_gold(delta: int):
	player_data.gold += delta
	SignalBus.gold_changed.emit(player_data.gold)
```

### Step 4: Update Game Scene to Use SignalBus
**File:** `scenes/view/game_scene.gd`

```gdscript
extends Control

# Preload the debug popup scene
const DEBUG_POPUP = preload("res://scenes/windows/debug_popup.tscn")

func _ready():
	# Connect to SignalBus signals
	_connect_signals()

	# Initialize the game when scene loads
	GameManager.initialize_new_game()

func _connect_signals():
	# Connect to SignalBus instead of GameManager
	SignalBus.player_data_initialized.connect(_on_player_data_ready)
	SignalBus.week_advanced.connect(_on_week_advanced)
	SignalBus.gold_changed.connect(_on_gold_changed)

func _on_player_data_ready():
	# Show debug popup with player data
	show_debug_popup()

func _on_week_advanced(week: int):
	print("Week advanced to: ", week)
	# Update UI to show new week

func _on_gold_changed(new_amount: int):
	print("Gold changed to: ", new_amount)
	# Update gold display in UI

func show_debug_popup():
	var popup = DEBUG_POPUP.instantiate()
	add_child(popup)

	if popup.has_method("set_player_data"):
		popup.set_player_data(GameManager.player_data)

	popup.popup_centered()
```

### Step 5: Create Debug Popup Script
**File:** `scenes/windows/debug_popup.gd`

```gdscript
extends AcceptDialog

var player_data: PlayerData

func _ready():
	title = "Debug Info"
	dialog_text = ""
	add_cancel_button("Close")

	# Connect to SignalBus for live updates
	SignalBus.creature_stats_changed.connect(_on_creature_stats_changed)
	SignalBus.gold_changed.connect(_on_gold_changed)

func _on_creature_stats_changed(creature: CreatureData):
	# Refresh display when stats change
	if player_data and creature in player_data.creatures:
		update_display()

func _on_gold_changed(new_amount: int):
	# Refresh display when gold changes
	if player_data:
		update_display()

func set_player_data(data: PlayerData):
	player_data = data
	update_display()

func update_display():
	if not player_data:
		dialog_text = "No player data available"
		return

	var info = "=== PLAYER DATA ===\n"
	info += "Gold: %d\n" % player_data.gold
	info += "Week: %d\n" % GameManager.current_week
	info += "Total Creatures: %d\n\n" % player_data.creatures.size()

	for i in range(player_data.creatures.size()):
		var creature = player_data.creatures[i]
		info += "=== CREATURE %d ===\n" % (i + 1)
		info += "Name: %s\n" % creature.creature_name
		info += "Species: %s\n" % _get_species_name(creature.species)
		info += "Strength: %d\n" % creature.strength
		info += "Agility: %d\n" % creature.agility
		info += "Intelligence: %d\n\n" % creature.intelligence

	dialog_text = info

func _get_species_name(species: GlobalEnums.Species) -> String:
	match species:
		GlobalEnums.Species.SCUTTLEGUARD:
			return "Scuttleguard"
		GlobalEnums.Species.SLIME:
			return "Slime"
		GlobalEnums.Species.WIND_DANCER:
			return "Wind Dancer"
		_:
			return "Unknown"

func _on_canceled():
	# Clean up connections when popup closes
	SignalBus.popup_closed.emit("debug_popup")
	queue_free()
```

## Testing the SignalBus

1. **Run the game** and click "Start Game"
2. **Verify the debug popup** shows player and creature data
3. **Test signal connections** by adding a button to advance week:

```gdscript
# Add to game_scene.gd for testing
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Press Enter/Space
		GameManager.advance_week()
		print("Week advanced via SignalBus!")
```

## Best Practices

### DO:
- ✅ Define all signals in SignalBus
- ✅ Use descriptive signal names
- ✅ Emit signals with relevant data
- ✅ Disconnect signals when nodes are freed
- ✅ Group related signals with comments

### DON'T:
- ❌ Create direct connections between unrelated systems
- ❌ Emit signals from SignalBus itself (it's just a hub)
- ❌ Use SignalBus for node-specific signals (like button clicks)
- ❌ Forget to check if data exists before emitting

## Common Patterns

### Pattern 1: Request/Response
```gdscript
# Request from UI
SignalBus.show_creature_details_requested.emit(creature)

# Handler in another system
func _ready():
	SignalBus.show_creature_details_requested.connect(_show_creature_details)
```

### Pattern 2: State Changes
```gdscript
# Emit when state changes
SignalBus.gold_changed.emit(new_amount)

# Multiple systems can react
# HUD updates display
# Sound system plays coin sound
# Achievement system checks for milestones
```

### Pattern 3: Game Flow
```gdscript
# Chain of events through SignalBus
SignalBus.game_started.emit()
# -> Triggers player initialization
# -> Triggers UI setup
# -> Triggers music change
```

## Debugging SignalBus

Add this to SignalBus for debugging:
```gdscript
func _ready():
	# Debug mode - log all signal emissions
	if OS.is_debug_build():
		player_data_initialized.connect(func(): print("[SignalBus] player_data_initialized"))
		week_advanced.connect(func(w): print("[SignalBus] week_advanced: ", w))
		gold_changed.connect(func(g): print("[SignalBus] gold_changed: ", g))
		# Add more as needed
```

## Next Steps

With SignalBus in place, you can:
1. Add new features without modifying existing code
2. Create achievement system that listens to all events
3. Add sound manager that responds to game events
4. Implement save/load by capturing SignalBus state
5. Create tutorial system that tracks player actions

## Benefits You'll Notice

- **Cleaner Code**: No more `get_node()` chains
- **Easier Testing**: Can emit signals manually to test UI
- **Better Organization**: All communication in one place
- **Scalability**: Adding features doesn't break existing code
- **Debugging**: Can monitor all game events easily
# Game Initialization Implementation Guide

## Overview
This guide walks through implementing the game initialization flow:
**Main Menu → Start Game → Initialize Player Data → Create Starter Creature → Display in Debug Popup**

## Understanding the Current Architecture

### Current Problems:
1. **GameManager** initializes data in `_ready()` - happens too early
2. Player data is scattered (gold separate from creatures)
3. No proper flow from menu to game initialization
4. Debug popup isn't connected to display data

### What We're Building:
```
[Main Menu] --click start--> [Game Scene] --initialize--> [GameManager]
								   |                           |
								   |                           v
								   |                    [Player Data]
								   |                    [Starter Creature]
								   |                           |
								   v                           |
							  [Debug Popup] <--display data----+
```

## Step-by-Step Implementation

### Step 1: Update GameManager
**File:** `core/game_manager.gd`

**Why:** We need to separate game initialization from singleton loading

```gdscript
# scripts/game_manager.gd (Singleton)
extends Node

var current_week: int = 1
var player_data: PlayerData  # Changed from separate gold/creature vars

signal week_advanced(week: int)
signal stats_changed()
signal player_data_initialized()  # New signal for UI updates

func _ready():
	# Don't initialize here anymore - wait for new game
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

	# Signal that data is ready
	player_data_initialized.emit()

func advance_week():
	current_week += 1
	process_training()
	week_advanced.emit(current_week)

func process_training():
	# Updated to work with creatures array
	for creature in player_data.creatures:
		if creature.get("assigned_facility"):
			creature.strength += 5
			creature.agility += 3
			stats_changed.emit()

func get_active_creature() -> CreatureData:
	if player_data and player_data.creatures.size() > 0:
		return player_data.creatures[0]
	return null
```

### Step 2: Update Game Scene Script
**File:** `scenes/view/game_scene.gd`

**Why:** The game scene needs to trigger initialization and show debug popup

```gdscript
extends Control

# Preload the debug popup scene
const DEBUG_POPUP = preload("res://scenes/windows/debug_popup.tscn")

func _ready():
	# Initialize the game when scene loads
	GameManager.initialize_new_game()

	# Connect to know when data is ready
	GameManager.player_data_initialized.connect(_on_player_data_ready)

func _on_player_data_ready():
	# Show debug popup with player data
	show_debug_popup()

func show_debug_popup():
	# Create and display the debug popup
	var popup = DEBUG_POPUP.instantiate()
	add_child(popup)

	# Pass the data to the popup
	if popup.has_method("set_player_data"):
		popup.set_player_data(GameManager.player_data)

	# Center the popup on screen
	popup.popup_centered()
```

### Step 3: Create Debug Popup Script
**File:** Create new file `scenes/windows/debug_popup.gd`

**Why:** The popup needs logic to display player and creature data

```gdscript
extends AcceptDialog

var player_data: PlayerData

func _ready():
	# Set up the dialog
	title = "Debug Info"
	dialog_text = ""
	add_cancel_button("Close")

func set_player_data(data: PlayerData):
	player_data = data
	update_display()

func update_display():
	if not player_data:
		dialog_text = "No player data available"
		return

	var info = "=== PLAYER DATA ===\n"
	info += "Gold: %d\n" % player_data.gold
	info += "Total Creatures: %d\n\n" % player_data.creatures.size()

	# Display each creature
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
```

### Step 4: Update Debug Popup Scene (if needed)
**File:** `scenes/windows/debug_popup.tscn`

In the Godot editor:
1. Open `debug_popup.tscn`
2. Select the root node
3. In the Inspector, attach the script: `res://scenes/windows/debug_popup.gd`
4. Make sure the root node is an `AcceptDialog` or `ConfirmationDialog`

## Testing the Implementation

1. **Run the game** (F5 in Godot)
2. **Click "Start Game"** on the main menu
3. **Verify the debug popup appears** with:
   - Player gold: 100
   - One creature named "Scuttle"
   - Species: Scuttleguard
   - Stats: STR 10, AGI 8, INT 6

## Common Issues and Solutions

### Issue: Debug popup doesn't appear
- Check that `game_scene.gd` is attached to the game scene
- Verify the debug popup scene path is correct
- Check console for errors

### Issue: Data not showing in popup
- Ensure `set_player_data()` is being called
- Verify the popup script is attached to the scene
- Check that PlayerData has creatures array initialized

### Issue: Scene transition fails
- Verify the game scene path in main_menu.gd
- Check that the scene file exists and isn't corrupted

## Next Steps

After this works, you can:
1. Style the debug popup with better formatting
2. Add more starter creature options
3. Implement creature selection screen
4. Add animations to scene transitions
5. Create a proper HUD instead of debug popup

## Key Learning Points

1. **Singleton Pattern**: GameManager persists across scenes
2. **Signal Pattern**: Use signals to notify when async operations complete
3. **Resource Classes**: PlayerData and CreatureData organize related data
4. **Scene Instantiation**: Use `preload()` and `instantiate()` for dynamic scenes
5. **Data Flow**: Main Menu → Game Scene → GameManager → UI Components

## Architecture Benefits

- **Separation of Concerns**: GameManager handles logic, scenes handle display
- **Reusability**: PlayerData can be saved/loaded easily
- **Extensibility**: Easy to add more creatures or player properties
- **Debugging**: Debug popup can be reused throughout development

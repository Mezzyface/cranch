# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.5 game project that appears to be a creature management/training game. The project uses GDScript and follows Godot's scene-based architecture with a centralized SignalBus pattern.

## Development Commands

### Running the Project
- Use Godot 4.5 editor to open `project.godot`
- Main scene: `scenes/view/main_menu.tscn`
- Press F5 in Godot editor to run the project
- Press F6 to run the current scene

### Godot CLI Commands (if available)
```bash
# Run the project
godot --path .

# Run a specific scene
godot --path . scenes/view/main_menu.tscn

# Export project (requires export templates)
godot --headless --export-release "Windows Desktop" build/game.exe
```

## Architecture & Structure

### Core Systems

1. **Game Manager** (`core/game_manager.gd`)
   - Singleton that manages game state
   - Handles week progression system
   - Manages player resources (gold, creatures)
   - Emits signals for game events

2. **Signal Bus** (`core/signal_bus.gd`)
   - Central signal routing system (currently empty, likely for future expansion)

3. **Global Enums** (`core/global_enums.gd`)
   - Autoloaded singleton for game-wide enumerations

### Resource Classes

- **CreatureData** (`resources/creature_data.gd`): Resource class for creature stats (strength, agility, intelligence)
- **FacilityData** (`resources/facility_data.gd`): Placeholder for facility system
- **ActivityData** (`resources/activity_data.gd`): Likely for creature activities/training

### Scene Structure

- `scenes/view/`: Main game views (main_menu, game_scene)
- `scenes/windows/`: Popup windows and UI panels
- `ui/`: UI components and themes

### Project Configuration

- **Display**: 1920x1080 viewport
- **Renderer**: GL Compatibility mode (for broader device support)
- **Autoloads**: GlobalEnums singleton
- **Custom theme and fonts configured**

## Key Development Patterns

1. **Scene Transitions**: Use `get_tree().change_scene_to_packed()` with preloaded scenes
2. **Data Management**: Use Godot Resource classes for game data
3. **Signal Communication**: All signals go through centralized SignalBus singleton
4. **File Organization**:
   - Core game logic in `/core`
   - Data structures in `/resources`
   - UI scenes in `/scenes`

## Current State of Project

**What's Working:**
- Complete game initialization flow
- Creatures spawn and wander in bounded container
- Creatures show random emotes periodically
- Save/Load system with F5/F9 and menu integration
- Two test creatures (Scuttle the Scuttleguard, Squish the Slime)

**Last Task Completed:**
- Creature generation system with species-based stat curves
- Resource-based shop system (in DEVELOPMENT_GUIDE.md)

**Ready for Next Features:**
- Shop system implementation (planned in DEVELOPMENT_GUIDE.md)
- UI/HUD improvements
- Battle system
- Breeding/genetics system
- More facilities and activities

## Working with This Project - IMPORTANT

### Development Workflow
This project uses a **guided development approach** with a living documentation system:

1. **DEVELOPMENT_GUIDE.md** is the primary working document
   - Contains current architecture and signal flow
   - Has an "Implementation Steps Section" for new features
   - Tracks completed implementations
   - Updates as the project grows

2. **When the user requests a feature:**
   - **ONLY UPDATE DEVELOPMENT_GUIDE.md** - Never modify code files directly
   - Clear previous task steps when starting new feature
   - Add implementation steps to DEVELOPMENT_GUIDE.md using this format:
     - File name at the top
     - Individual changes as numbered steps
     - Show line numbers, before/after code, and reasoning
   - Don't paste entire code files
   - Update architecture documentation after completion
   - Move completed work to the history section
   - **The user will implement the code changes based on the guide**

3. **Signal-Driven Architecture:**
   - All inter-system communication goes through SignalBus
   - Never create direct connections between unrelated systems
   - Always document new signals in DEVELOPMENT_GUIDE.md

4. **Implementation Pattern:**
   - User requests feature → Add steps to guide → User implements → Update architecture docs
   - Always explain WHY changes are being made, not just WHAT
   - Provide complete code blocks that can be copied directly
   - **When user asks for breakdown:** Provide detailed explanations with:
     - Problem being solved
     - Why each change is necessary
     - How each part works technically
     - Alternative approaches and why they weren't chosen
     - Visual representations when helpful

### Current Architecture Summary

#### Autoload Order (Important!)
1. **GlobalEnums**: Game-wide enumerations (Species, CreatureState, FacingDirection, Emote, ShopEntryType)
2. **SignalBus**: Central signal hub - all inter-system communication
3. **GameManager**: Game state, player data, week progression
4. **SaveManager**: Handles all save/load operations

#### Core Systems Implemented

**Creature System:**
- CreatureDisplay scenes with wandering AI
- Container-bound movement with padding
- State machine (IDLE/WALKING)
- Directional animations (walk-up/down/left/right)
- Random emote bubbles (15 types)
- Click detection for stats popup
- Drag/drop system via DragDropComponent
- Species-based procedural generation with stat curves

**Save/Load System:**
- SaveManager singleton handles persistence
- Resource-based saves at `user://savegame.tres`
- F5 to save, F9 to load
- Main menu continue button integration

**Facility System:**
- Drag/drop creatures into facility slots
- Multi-slot facilities with capacity limits
- Activity execution on week advancement
- FacilityManager tracks assignments
- Facility slot unlocking (costs gold)
- FacilityCard scene for UI display

**Data Architecture:**
- PlayerData: Resource containing gold and creatures array
- CreatureData: Resource with name, species, stats
- SaveGame: Resource for serializing game state
- FacilityResource: Defines facility behavior and activities
- ActivityResource: Base class for stat modifications and transformations
- CreatureGenerator: Static utility for procedural creature generation

#### Key Patterns

**SignalBus Pattern:**
- Never connect systems directly
- All signals defined in SignalBus
- Example: GameManager emits → SignalBus → UI receives

**Resource-Based Data:**
- All game data as Godot Resources
- Enables easy save/load
- Type-safe with exports

**Manager Separation:**
- GameManager: Game logic only
- SaveManager: Persistence only
- Each manager has single responsibility

### File References
- Main working document: `DEVELOPMENT_GUIDE.md`
- Signal definitions: `core/signal_bus.gd`
- Game state: `core/game_manager.gd`
- Save operations: `core/save_manager.gd`
- Facility assignments: `core/managers/facility_manager.gd`
- Shop logic: `scripts/shop_manager.gd` (non-autoload utility)
- Data structures: `resources/` directory
- Creature generation: `scripts/creature_generation.gd`
- Drag/drop system: `scripts/drag_drop_component.gd`
- Creature logic: `scenes/entities/creature_display.gd`
- Facility UI: `scenes/card/facility_card.gd`, `scenes/card/facility_slot.gd`
- Main game scene: `scenes/view/game_scene.gd`

### Current Game Flow

1. **Main Menu** → Start Game or Continue
2. **Game Scene** emits `game_started` signal
3. **GameManager** receives signal, calls `initialize_new_game()`
4. **GameManager** creates PlayerData with starter creatures
5. **SignalBus** emits `player_data_initialized` and `creature_added`
6. **Game Scene** spawns creatures in CreatureContainer
7. **Creatures** wander with AI, show emotes, respect boundaries

### Testing Commands
- F5: Quick save
- F9: Quick load
- Check saves at: `%APPDATA%\Godot\app_userdata\[project_name]\`

### Common Tasks Reference

**Add new creature species:**
1. Add to GlobalEnums.Species enum
2. Add sprite path to SPECIES_SPRITE_FRAMES
3. Create sprite resource in assets/sprites/creatures/

**Add new emote:**
1. Add to GlobalEnums.Emote enum
2. Add texture path in emote_bubble.gd EMOTE_TEXTURES
3. Add image to assets/emotes/review/

**Add new signal:**
1. Define in SignalBus
2. Emit from source system
3. Connect in receiving systems
4. Document in DEVELOPMENT_GUIDE

**Generate a new creature:**
1. Use `CreatureGenerator.generate_creature(species, optional_name)`
2. Or use `GameManager.add_generated_creature(species, optional_name)` to add directly to player data
3. Species stat curves defined in `scripts/creature_generation.gd`

**Add drag/drop to new UI element:**
1. Create DragDropComponent instance
2. Configure drag_type, can_drag, can_accept_drops
3. Set proper z_index (100 for drop zones, 101+ for drag sources)
4. Connect signals: drag_started, drag_ended, drop_received
5. See DEVELOPMENT_GUIDE.md for detailed patterns


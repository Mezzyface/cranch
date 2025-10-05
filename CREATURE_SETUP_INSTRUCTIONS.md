# New Creature Setup - Final Steps

## What's Been Done

✅ **Extracted all 17 creature sprites** to `res://assets/sprites/creatures/`
- Each creature has its own folder with individual PNG animation frames
- Frames include: stand, move/chase, die, hit, attack animations

✅ **Updated GlobalEnums** (`res://core/global_enums.gd`)
- Replaced old species (SCUTTLEGUARD, SLIME, WIND_DANCER) with 17 new species
- Updated SPECIES_SPRITE_FRAMES paths to point to new .tres files

✅ **Updated Creature Generation** (`res://scripts/creature_generation.gd`)
- Added stat curves for all 17 new species
- Added name generation prefixes for all species
- Each species has unique stat distributions (strength, agility, intelligence)

## What You Need To Do

### Step 1: Generate SpriteFrames Resources

A helper script has been created to automatically generate SpriteFrames for all creatures.

1. Open your project in **Godot Editor**
2. Open the script: `res://create_spriteframes.gd`
3. Run it: **File → Run** (or press Ctrl+Shift+X)
4. The script will create `.tres` files for all 17 creatures

The script will:
- Read all `stand_*.png` and `move_*.png` frames from each creature folder
- Create SpriteFrames with animations: `idle`, `walk-up`, `walk-down`, `walk-left`, `walk-right`, `idle-up`, `idle-down`, `idle-left`, `idle-right`
- Save them to the correct paths (e.g., `res://assets/sprites/creatures/guard_robot/guard_robot.tres`)

### Step 2: Test the Creatures

After running the script:

1. Run your game (F5)
2. The game should now use the new creatures
3. Check that creatures appear and animate correctly

### Step 3: Clean Up Old Files (Optional)

Once everything is working:

1. Delete the old creature folders:
   - `res://assets/sprites/creatures/scuttleguard/`
   - `res://assets/sprites/creatures/slime/`
   - `res://assets/sprites/creatures/wind_dancer/`

2. Delete the helper files:
   - `res://create_spriteframes.gd`
   - `res://create_sprite_frames.py`
   - `res://CREATURE_SETUP_INSTRUCTIONS.md` (this file)

## New Creature List

1. **Guard Robot** - Tank (High STR, Low AGI, Med INT)
2. **Fire Pyrope** - Strong Elemental (Very High STR, Med AGI, Low INT)
3. **Illusionary Raccoon** - Trickster (Low STR, High AGI, High INT)
4. **Ore Muncher** - Powerhouse (Very High STR, Very Low AGI, Low INT)
5. **Neon Bat** - Speedster (Med-Low STR, Very High AGI, Med INT)
6. **Toy Trojan** - Balanced Fighter (Med STR, Med AGI, Med-Low INT)
7. **Robo** - Mechanical (Med STR, Med AGI, High INT)
8. **Froscola** - Balanced (Med STR, Med-High AGI, Med INT)
9. **Grizzly** - Beast (Very High STR, Low AGI, Low INT)
10. **Blazin' Sparkinstone Bugs** - Elemental Swarm (High STR, Med-High AGI, Med-Low INT)
11. **Stoplight Ghost** - Ghost (Med-Low STR, Med AGI, High INT)
12. **Haunted River Rock** - Rock Spirit (High STR, Low AGI, Med-High INT)
13. **Hedgehog** - Spiky Defender (Med STR, High AGI, Med-Low INT)
14. **Delinquent Chick** - Scrappy (Low STR, High AGI, Med INT)
15. **Ooze Waste** - Toxic (Med STR, Low AGI, High INT)
16. **Krip** - Mysterious (Perfectly Balanced - Med All Stats)
17. **Grave Robber's Hunting Dog** - Hunter (High STR, High AGI, Low INT)

## Troubleshooting

**If creatures don't appear:**
- Check the Output/Debugger panel for errors
- Verify `.tres` files were created in each creature folder
- Make sure the SpriteFrames have the correct animation names

**If animations don't play:**
- Open a `.tres` file in the editor and verify it has animations
- Check that `walk-down`, `walk-up`, `walk-left`, `walk-right` and `idle` animations exist

**If you see warnings about missing sprite profiles:**
- This means a species is in the enum but not in the SPECIES_STATS dictionary
- Check `creature_generation.gd` has all 17 species defined

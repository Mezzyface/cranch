#!/usr/bin/env python3
"""
Generate Godot SpriteFrames resources from extracted creature sprites.
These sprites are side-scroller style with stand/move animations only.
"""

import os
from pathlib import Path

# Creature mappings: folder_name -> (display_name, enum_name)
CREATURES = {
    "guard_robot": ("Guard Robot", "GUARD_ROBOT"),
    "fire_pyrope": ("Fire Pyrope", "FIRE_PYROPE"),
    "illusionary_raccoon": ("Illusionary Raccoon", "ILLUSIONARY_RACCOON"),
    "ore_muncher": ("Ore Muncher", "ORE_MUNCHER"),
    "neon_bat": ("Neon Bat", "NEON_BAT"),
    "toy_trojan": ("Toy Trojan", "TOY_TROJAN"),
    "robo": ("Robo", "ROBO"),
    "froscola": ("Froscola", "FROSCOLA"),
    "grizzly": ("Grizzly", "GRIZZLY"),
    "blazin_sparkinstone_bugs": ("Blazin' Sparkinstone Bugs", "BLAZIN_SPARKINSTONE_BUGS"),
    "stoplight_ghost": ("Stoplight Ghost", "STOPLIGHT_GHOST"),
    "haunted_river_rock": ("Haunted River Rock", "HAUNTED_RIVER_ROCK"),
    "hedgehog": ("Hedgehog", "HEDGEHOG"),
    "delinquent_chick": ("Delinquent Chick", "DELINQUENT_CHICK"),
    "ooze_waste": ("Ooze Waste", "OOZE_WASTE"),
    "krip": ("Krip", "KRIP"),
    "grave_robber_hunting_dog": ("Grave Robber's Hunting Dog", "GRAVE_ROBBER_HUNTING_DOG")
}

BASE_PATH = Path("C:/Users/purem/OneDrive/Documents/new-game-project/assets/sprites/creatures")

def get_frames_from_folder(folder_path):
    """Extract stand and move frames from sprite folder."""
    stand_frames = sorted([f for f in os.listdir(folder_path) if f.startswith("stand_")])
    move_frames = sorted([f for f in os.listdir(folder_path) if f.startswith("move_")])

    # Fallback to chase frames if move doesn't exist (for Grizzly)
    if not move_frames:
        move_frames = sorted([f for f in os.listdir(folder_path) if f.startswith("chase_")])

    return stand_frames, move_frames

def create_sprite_frames(folder_name, display_name, enum_name):
    """Create a .tres SpriteFrames resource for a creature."""
    folder_path = BASE_PATH / folder_name
    stand_frames, move_frames = get_frames_from_folder(folder_path)

    if not stand_frames or not move_frames:
        print(f"Warning: Missing frames for {folder_name}")
        return None

    # Build the resource file content
    lines = []
    lines.append('[gd_resource type="SpriteFrames" format=3]')
    lines.append('')
    lines.append('[resource]')
    lines.append('animations = [{')

    # For side-scroller sprites, we'll use:
    # - "idle" for all idle directions (just use stand frames)
    # - "walk-left", "walk-right", "walk-up", "walk-down" all use move frames
    # The sprite will be flipped in code if needed

    animations = []

    # Idle animation (used for all idle directions)
    idle_anim = []
    idle_anim.append('"frames": [')
    frame_entries = []
    for frame in stand_frames:
        frame_path = f'res://assets/sprites/creatures/{folder_name}/{frame}'
        frame_entries.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{frame_path}")\n}}')
    idle_anim.append(',\n'.join(frame_entries))
    idle_anim.append('],')
    idle_anim.append('"loop": true,')
    idle_anim.append('"name": &"idle",')
    idle_anim.append('"speed": 8.0')

    # Move animation (shared by all directions)
    move_anim = []
    move_anim.append('"frames": [')
    frame_entries = []
    for frame in move_frames:
        frame_path = f'res://assets/sprites/creatures/{folder_name}/{frame}'
        frame_entries.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{frame_path}")\n}}')
    move_anim.append(',\n'.join(frame_entries))
    move_anim.append('],')
    move_anim.append('"loop": true,')
    move_anim.append('"name": &"walk",')
    move_anim.append('"speed": 8.0')

    # Actually, let's simplify and just create "idle" and "walk-down" since the creature_display
    # will look for walk-up, walk-down, etc. We'll duplicate walk for all directions

    animations_data = []

    # Create idle animation
    animations_data.append('{\n' + '\n'.join(idle_anim) + '\n}')

    # Create walk animations for all 4 directions (same frames, different names)
    for direction in ["walk-down", "walk-left", "walk-right", "walk-up"]:
        walk_anim = []
        walk_anim.append('"frames": [')
        frame_entries = []
        for frame in move_frames:
            frame_path = f'res://assets/sprites/creatures/{folder_name}/{frame}'
            frame_entries.append(f'{{\n"duration": 1.0,\n"texture": ExtResource("{frame_path}")\n}}')
        walk_anim.append(',\n'.join(frame_entries))
        walk_anim.append('],')
        walk_anim.append('"loop": true,')
        walk_anim.append(f'"name": &"{direction}",')
        walk_anim.append('"speed": 8.0')
        animations_data.append('{\n' + '\n'.join(walk_anim) + '\n}')

    lines.append(',\n'.join(animations_data))
    lines.append('}]')

    # Hmm, this approach won't work well because ExtResource needs proper resource loading
    # Let me use a different approach - individual textures loaded as external resources

    return None  # Will implement differently

# Actually, let's just create them using Godot's editor instead
# I'll generate a GDScript that can be run to create the resources

print("Due to Godot's resource format complexity, SpriteFrames should be created in Godot editor.")
print("However, we can still proceed by updating the global_enums.gd with placeholders.")
print("\nCreatures to add:")
for folder, (name, enum) in CREATURES.items():
    print(f"  - {name} ({enum}): {BASE_PATH / folder}")

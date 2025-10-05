# Quest & Activity System Update

## Overview
Updated the quest and activity systems to work with the new 1000-point stat scale and 17 new creature species.

---

## ✅ Activities Updated

### Basic Training (Updated)
All basic training activities now use the 1000-point scale:

- **Strength Training**: +50 STR
- **Agility Training**: +50 AGI
- **Intelligence Training**: +50 INT
- **Balanced Training**: +30 to all stats

### Advanced Training (NEW)
New specialized training activities with trade-offs:

- **Power Training**: +75 STR, -15 AGI
  - For creatures focusing on raw power

- **Speed Training**: +75 AGI, -15 STR
  - For creatures focusing on speed

- **Tactical Training**: +75 INT, -15 STR
  - For creatures focusing on intelligence

- **Rest & Recovery**: +20 to all stats
  - Gentle training with no drawbacks

- **Extreme Training**: Adaptive 2-week training
  - +100 to highest stat
  - +50 to secondary stat
  - Automatically trains based on creature's natural strengths

---

## ✅ Quests Updated

### Quest Scripts Created

1. **update_old_quests.gd** - Updates existing 5 quests
   - Converts old 1-20 stat requirements to 1000-point scale
   - Updates species from old creatures to new ones
   - Run in Godot: File → Run

2. **create_new_quests.gd** - Creates 8 new quests
   - Quests designed for new creature species
   - Various difficulty levels
   - Run in Godot: File → Run

### New Quests Created

| Quest ID | Title | Giver | Species | Requirements | Reward |
|----------|-------|-------|---------|--------------|--------|
| GUARD-01 | Mechanical Guardian | The Engineer | Guard Robot | STR ≥ 500 | 500 gold |
| SPEED-01 | Lightning Fast | The Racer | Neon Bat | AGI ≥ 550 | 600 gold |
| BRAIN-01 | The Trickster's Challenge | The Puzzle Master | Illusionary Raccoon | INT ≥ 550 | 700 gold |
| BEAST-01 | Call of the Wild | The Beast Tamer | Grizzly | STR ≥ 700 | 800 gold |
| BAL-01 | The Perfect Specimen | The Collector | Krip | STR/AGI/INT ≥ 450 | 1000 gold |
| HUNT-01 | Spectral Hunter | The Gravekeeper | Grave Robber's Hunting Dog | STR ≥ 500, AGI ≥ 550 | 650 gold |
| ELEM-01 | Fire and Stone | The Alchemist | Fire Pyrope | STR ≥ 600 | 700 gold |
| POWER-01 | Show of Strength | The Arena Master | Any Species | STR ≥ 700 | 1200 gold |

### Updated Old Quests

| Quest ID | Original | New Version |
|----------|----------|-------------|
| COL-01 | Scuttleguard STR ≥ 15 | Guard Robot STR ≥ 750 |
| COL-02 | Slime (balanced) | Krip STR/AGI/INT ≥ 450 |
| COL-03 | Wind Dancer INT ≥ 12 | Illusionary Raccoon INT ≥ 550 |
| COL-04 | Any creature with high stats | Any creature STR/AGI/INT ≥ 600 |
| COL-05 | Multiple creatures | 3 different creatures with 600+ in specific stats |

---

## 🎯 How To Use

### Step 1: Update Old Quests
1. Open Godot Editor
2. Open `res://update_old_quests.gd`
3. Run it: **File → Run** (or Ctrl+Shift+X)
4. Existing 5 quests will be updated to new stat scale

### Step 2: Create New Quests
1. Open `res://create_new_quests.gd`
2. Run it: **File → Run** (or Ctrl+Shift+X)
3. 8 new quests will be created in `resources/quests/`

### Step 3: Test Activities
Activities are ready to use! They'll automatically work with the new stat scale.

---

## 📊 Stat Scale Reference

### Old Scale (1-20) → New Scale (0-1000)

| Old Value | New Value | Category |
|-----------|-----------|----------|
| 5 | 250 | Low |
| 10 | 500 | Medium |
| 15 | 750 | High |
| 20 | 1000 | Maximum |

### Typical Creature Stat Ranges

- **Low**: 200-350
- **Medium**: 400-550
- **High**: 600-750
- **Very High**: 750-900

---

## 🧪 Suggested Progression

1. **Early Game**: Basic training (+50 per stat)
2. **Mid Game**: Advanced training (+75/-15 trade-offs)
3. **Late Game**: Extreme training (+100/+50 over 2 weeks)

### Training Strategy Examples

**For Guard Robot (Tank)**:
- Use Power Training to maximize strength
- Use Rest & Recovery to maintain other stats

**For Neon Bat (Speedster)**:
- Use Speed Training to maximize agility
- Avoid Power Training (would reduce speed)

**For Krip (Balanced)**:
- Use Balanced Training or Rest & Recovery
- Avoid specialized training with penalties

---

## 🗑️ Cleanup (After Testing)

Once everything works:
1. Delete `update_old_quests.gd`
2. Delete `create_new_quests.gd`
3. Delete this file (`QUEST_AND_ACTIVITY_UPDATE.md`)

---

## 📝 Notes

- Quest requirements now use realistic stat values for 1000-point scale
- Activities provide meaningful progression without being overpowered
- Advanced activities introduce strategic choices (trade-offs)
- Extreme Training adapts to each creature's natural strengths

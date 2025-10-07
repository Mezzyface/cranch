extends Node

enum Species {
	GUARD_ROBOT,
	FIRE_PYROPE,
	ILLUSIONARY_RACCOON,
	ORE_MUNCHER,
	NEON_BAT,
	TOY_TROJAN,
	ROBO,
	FROSCOLA,
	GRIZZLY,
	BLAZIN_SPARKINSTONE_BUGS,
	STOPLIGHT_GHOST,
	HAUNTED_RIVER_ROCK,
	HEDGEHOG,
	DELINQUENT_CHICK,
	OOZE_WASTE,
	KRIP,
	GRAVE_ROBBER_HUNTING_DOG
}

const SPECIES_SPRITE_FRAMES = {
	Species.GUARD_ROBOT: "res://assets/sprites/creatures/guard_robot/guard_robot.tres",
	Species.FIRE_PYROPE: "res://assets/sprites/creatures/fire_pyrope/fire_pyrope.tres",
	Species.ILLUSIONARY_RACCOON: "res://assets/sprites/creatures/illusionary_raccoon/illusionary_raccoon.tres",
	Species.ORE_MUNCHER: "res://assets/sprites/creatures/ore_muncher/ore_muncher.tres",
	Species.NEON_BAT: "res://assets/sprites/creatures/neon_bat/neon_bat.tres",
	Species.TOY_TROJAN: "res://assets/sprites/creatures/toy_trojan/toy_trojan.tres",
	Species.ROBO: "res://assets/sprites/creatures/robo/robo.tres",
	Species.FROSCOLA: "res://assets/sprites/creatures/froscola/froscola.tres",
	Species.GRIZZLY: "res://assets/sprites/creatures/grizzly/grizzly.tres",
	Species.BLAZIN_SPARKINSTONE_BUGS: "res://assets/sprites/creatures/blazin_sparkinstone_bugs/blazin_sparkinstone_bugs.tres",
	Species.STOPLIGHT_GHOST: "res://assets/sprites/creatures/stoplight_ghost/stoplight_ghost.tres",
	Species.HAUNTED_RIVER_ROCK: "res://assets/sprites/creatures/haunted_river_rock/haunted_river_rock.tres",
	Species.HEDGEHOG: "res://assets/sprites/creatures/hedgehog/hedgehog.tres",
	Species.DELINQUENT_CHICK: "res://assets/sprites/creatures/delinquent_chick/delinquent_chick.tres",
	Species.OOZE_WASTE: "res://assets/sprites/creatures/ooze_waste/ooze_waste.tres",
	Species.KRIP: "res://assets/sprites/creatures/krip/krip.tres",
	Species.GRAVE_ROBBER_HUNTING_DOG: "res://assets/sprites/creatures/grave_robber_hunting_dog/grave_robber_hunting_dog.tres"
}

# Species-specific maximum lifespans (in weeks)
# Balanced for training (30 weeks), competitions (10 weeks), and breeding (10 weeks)
const SPECIES_LIFESPANS = {
	Species.GUARD_ROBOT: 100,             # Mechanical, long-lasting
	Species.FIRE_PYROPE: 75,              # Elemental, moderate
	Species.ILLUSIONARY_RACCOON: 65,      # Trickster, shorter
	Species.ORE_MUNCHER: 85,              # Hardy, rock-based
	Species.NEON_BAT: 70,                 # Fast metabolism
	Species.TOY_TROJAN: 90,               # Toy-like durability
	Species.ROBO: 100,                    # Mechanical
	Species.FROSCOLA: 68,                 # Amphibian-like
	Species.GRIZZLY: 80,                  # Bear-like longevity
	Species.BLAZIN_SPARKINSTONE_BUGS: 60, # Insect-like, short
	Species.STOPLIGHT_GHOST: 120,         # Ghost, very long
	Species.HAUNTED_RIVER_ROCK: 110,      # Ancient stone
	Species.HEDGEHOG: 72,                 # Small mammal
	Species.DELINQUENT_CHICK: 65,         # Young bird
	Species.OOZE_WASTE: 60,               # Unstable slime
	Species.KRIP: 75,                     # Balanced
	Species.GRAVE_ROBBER_HUNTING_DOG: 78  # Canine-like
}

enum CreatureState {
	IDLE,
	WALKING
}

enum FacingDirection {
	WALK_UP,
	WALK_DOWN,
	WALK_LEFT,
	WALK_RIGHT,
	IDLE_UP,
	IDLE_DOWN,
	IDLE_LEFT,
	IDLE_RIGHT
}


# Animation name mapping
const FACING_ANIMATION_NAMES = {
	FacingDirection.WALK_UP: "walk-up",
	FacingDirection.WALK_DOWN: "walk-down",
	FacingDirection.WALK_LEFT: "walk-left",
	FacingDirection.WALK_RIGHT: "walk-right",
	FacingDirection.IDLE_UP: "idle-up",
	FacingDirection.IDLE_DOWN: "idle-down",
	FacingDirection.IDLE_LEFT: "idle-left",
	FacingDirection.IDLE_RIGHT: "idle-right"
}

enum Emote {
	HAPPY,
	JOYFUL,
	FRUSTRATED,
	CRYING,
	CHEERFUL,
	LAUGHING,
	SLEEPING,
	PLEASED,
	SHOCKED,
	GIGGLING,
	LOVE,
	DROWSY,
	WORRIED,
	EXCITED,
	ANGRY
}

enum ShopEntryType {
	CREATURE,     # Purchase generates a creature directly
	ITEM,         # Purchase gives an item to inventory
	SERVICE       # Purchase triggers an immediate action
}

# Tag categories (tags can belong to multiple)
enum TagCategory {
	SPECIES,   # Innate tags from species
	TRAINING,  # Earned through activities
	BREEDING,  # Inherited from parents
	SPECIAL,   # Event/quest rewards
	NEGATIVE,   # Debuffs/challenges
	TRAIT
}

enum CreatureProperties {
	TRAIT,
	GROWTH,
	PERSONALITY
}

enum ItemType {
	FOOD,
	EQUIPMENT,
	CONSUMABLE,
	MATERIAL,
	SPECIAL
}

enum CompetitionType {
	STRENGTH_CONTEST,    # Tests strength stat
	SPEED_RACE,          # Tests agility stat
	PUZZLE_TOURNAMENT,   # Tests intelligence stat
	TRIATHLON            # Tests all stats
}

enum CompetitionDifficulty {
	EASY,      # AI opponents: 30-100 primary stat (untrained)
	MEDIUM,    # AI opponents: 150-300 primary stat (partially trained)
	HARD,      # AI opponents: 400-600 primary stat (well-trained)
	EXPERT     # AI opponents: 700-1000 primary stat (maxed)
}

func get_animation_name(direction: FacingDirection) -> String:
	return FACING_ANIMATION_NAMES.get(direction, "idle")

func get_species_lifespan(species: Species) -> int:
	return SPECIES_LIFESPANS.get(species, 30)  # Default to 30 if not found

func get_sprite_frames_for_species(species: Species) -> SpriteFrames:
	if species in SPECIES_SPRITE_FRAMES:
		return load(SPECIES_SPRITE_FRAMES[species]) as SpriteFrames
	else:
		print("No sprite frames found for species: ", species)
		return null

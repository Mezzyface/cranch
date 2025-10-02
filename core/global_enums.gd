extends Node

enum Species {
	SCUTTLEGUARD,
	SLIME,
	WIND_DANCER
}

const SPECIES_SPRITE_FRAMES = {
	Species.SCUTTLEGUARD: "res://assets/sprites/creatures/scuttleguard/scutleguard.tres",
	Species.SLIME: "res://assets/sprites/creatures/slime/slime.tres",
	Species.WIND_DANCER: "res://assets/sprites/creatures/wind_dancer/wind_dancer.tres"
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

func get_animation_name(direction: FacingDirection) -> String:
	return FACING_ANIMATION_NAMES.get(direction, "idle")
	
func get_sprite_frames_for_species(species: Species) -> SpriteFrames:
	if species in SPECIES_SPRITE_FRAMES:
		return load(SPECIES_SPRITE_FRAMES[species]) as SpriteFrames
	else:
		print("No sprite frames found for species: ", species)
		return null

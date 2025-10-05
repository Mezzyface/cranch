# scripts/creature_generation.gd
class_name CreatureGenerator

# Species stat templates: [base_value, variance]
# Stats are generated as: base ± variance using normal distribution
# Stats range from 0-1000
const SPECIES_STATS = {
	GlobalEnums.Species.GUARD_ROBOT: {
		"strength": [550, 150],      # Tank - High strength
		"agility": [250, 100],       # Low agility
		"intelligence": [450, 100]   # Medium intelligence
	},
	GlobalEnums.Species.FIRE_PYROPE: {
		"strength": [650, 150],      # Strong elemental - High strength
		"agility": [350, 100],       # Medium agility
		"intelligence": [300, 100]   # Lower intelligence
	},
	GlobalEnums.Species.ILLUSIONARY_RACCOON: {
		"strength": [300, 100],      # Trickster - Low strength
		"agility": [550, 150],       # High agility
		"intelligence": [600, 150]   # High intelligence
	},
	GlobalEnums.Species.ORE_MUNCHER: {
		"strength": [700, 150],      # Powerful - Very high strength
		"agility": [200, 100],       # Very low agility
		"intelligence": [250, 100]   # Low intelligence
	},
	GlobalEnums.Species.NEON_BAT: {
		"strength": [350, 100],      # Speedy - Medium-low strength
		"agility": [650, 150],       # Very high agility
		"intelligence": [400, 100]   # Medium intelligence
	},
	GlobalEnums.Species.TOY_TROJAN: {
		"strength": [500, 100],      # Balanced fighter - Medium strength
		"agility": [450, 100],       # Medium agility
		"intelligence": [350, 100]   # Medium-low intelligence
	},
	GlobalEnums.Species.ROBO: {
		"strength": [450, 100],      # Mechanical - Medium strength
		"agility": [400, 100],       # Medium agility
		"intelligence": [550, 150]   # High intelligence
	},
	GlobalEnums.Species.FROSCOLA: {
		"strength": [400, 100],      # Balanced - Medium strength
		"agility": [500, 100],       # Medium-high agility
		"intelligence": [450, 100]   # Medium intelligence
	},
	GlobalEnums.Species.GRIZZLY: {
		"strength": [750, 150],      # Beast - Very high strength
		"agility": [300, 100],       # Low agility
		"intelligence": [200, 100]   # Low intelligence
	},
	GlobalEnums.Species.BLAZIN_SPARKINSTONE_BUGS: {
		"strength": [600, 150],      # Elemental swarm - High strength
		"agility": [500, 100],       # Medium-high agility
		"intelligence": [350, 100]   # Medium-low intelligence
	},
	GlobalEnums.Species.STOPLIGHT_GHOST: {
		"strength": [350, 100],      # Ghost - Medium-low strength
		"agility": [450, 100],       # Medium agility
		"intelligence": [600, 150]   # High intelligence
	},
	GlobalEnums.Species.HAUNTED_RIVER_ROCK: {
		"strength": [550, 150],      # Rock spirit - High strength
		"agility": [250, 100],       # Low agility
		"intelligence": [500, 100]   # Medium-high intelligence
	},
	GlobalEnums.Species.HEDGEHOG: {
		"strength": [400, 100],      # Spiky defender - Medium strength
		"agility": [550, 150],       # High agility
		"intelligence": [350, 100]   # Medium-low intelligence
	},
	GlobalEnums.Species.DELINQUENT_CHICK: {
		"strength": [300, 100],      # Scrappy - Low strength
		"agility": [600, 150],       # High agility
		"intelligence": [400, 100]   # Medium intelligence
	},
	GlobalEnums.Species.OOZE_WASTE: {
		"strength": [450, 100],      # Toxic - Medium strength
		"agility": [300, 100],       # Low agility
		"intelligence": [550, 150]   # High intelligence
	},
	GlobalEnums.Species.KRIP: {
		"strength": [500, 100],      # Mysterious - Medium strength
		"agility": [500, 100],       # Medium agility
		"intelligence": [500, 100]   # Medium intelligence (balanced)
	},
	GlobalEnums.Species.GRAVE_ROBBER_HUNTING_DOG: {
		"strength": [550, 150],      # Hunter - High strength
		"agility": [600, 150],       # High agility
		"intelligence": [300, 100]   # Low intelligence
	}
}

# Generate a creature with stats based on species profile
static func generate_creature(species: GlobalEnums.Species, creature_name: String = "") -> CreatureData:
	var creature = CreatureData.new()

	# Set name (or generate random if not provided)
	creature.creature_name = creature_name if creature_name != "" else _generate_random_name(species)

	# Set species
	creature.species = species

	# Generate stats based on species profile
	if species in SPECIES_STATS:
		var profile = SPECIES_STATS[species]
		creature.strength = _generate_stat(profile["strength"])
		creature.agility = _generate_stat(profile["agility"])
		creature.intelligence = _generate_stat(profile["intelligence"])
	else:
		# Fallback if species not defined
		push_warning("No stat profile for species: %s, using defaults" % species)
		creature.strength = 500
		creature.agility = 500
		creature.intelligence = 500

	# Assign species-specific tags
	var species_tags = TagManager.get_species_tags(species)
	for tag in species_tags:
		TagManager.add_tag(creature, tag, true)  # silent=true during creation

	return creature

# Generate a stat value using normal distribution
# params: [base, variance] where stat = base ± variance
static func _generate_stat(params: Array) -> int:
	var base = params[0]
	var variance = params[1]

	# Use randfn for normal distribution (bell curve)
	# randfn(mean, deviation) - most values cluster around mean
	var value = randfn(base, variance / 2.0)  # Divide by 2 so most values stay within ± variance

	# Clamp to 0-1000 range
	return int(clamp(value, 0, 1000))

# Generate a random name based on species
static func _generate_random_name(species: GlobalEnums.Species) -> String:
	# Name pools per species
	var name_prefixes = {
		GlobalEnums.Species.GUARD_ROBOT: ["Sentinel", "Guard", "Patrol", "Steel", "Iron"],
		GlobalEnums.Species.FIRE_PYROPE: ["Blaze", "Ember", "Flame", "Pyro", "Scorch"],
		GlobalEnums.Species.ILLUSIONARY_RACCOON: ["Trick", "Mirage", "Phantom", "Shadow", "Mystic"],
		GlobalEnums.Species.ORE_MUNCHER: ["Chomp", "Boulder", "Munch", "Stone", "Crunch"],
		GlobalEnums.Species.NEON_BAT: ["Neon", "Glow", "Flash", "Spark", "Bright"],
		GlobalEnums.Species.TOY_TROJAN: ["Toy", "Wind", "Spring", "Tick", "Clock"],
		GlobalEnums.Species.ROBO: ["Robo", "Mech", "Bot", "Circuit", "Gear"],
		GlobalEnums.Species.FROSCOLA: ["Hop", "Leap", "Splash", "Pond", "Ribbit"],
		GlobalEnums.Species.GRIZZLY: ["Growl", "Claw", "Bear", "Roar", "Fur"],
		GlobalEnums.Species.BLAZIN_SPARKINSTONE_BUGS: ["Blaze", "Spark", "Swarm", "Bug", "Volt"],
		GlobalEnums.Species.STOPLIGHT_GHOST: ["Ghost", "Light", "Signal", "Glow", "Beam"],
		GlobalEnums.Species.HAUNTED_RIVER_ROCK: ["Stone", "River", "Haunt", "Spirit", "Rock"],
		GlobalEnums.Species.HEDGEHOG: ["Spike", "Prickle", "Hedge", "Quill", "Needle"],
		GlobalEnums.Species.DELINQUENT_CHICK: ["Punk", "Rebel", "Rogue", "Wild", "Scrappy"],
		GlobalEnums.Species.OOZE_WASTE: ["Gunk", "Sludge", "Toxic", "Waste", "Ooze"],
		GlobalEnums.Species.KRIP: ["Krip", "Mystery", "Enigma", "Curious", "Wonder"],
		GlobalEnums.Species.GRAVE_ROBBER_HUNTING_DOG: ["Hunter", "Howl", "Fang", "Grave", "Shadow"]
	}

	var suffixes = ["", "y", "ie", "ster", "ling", "let"]

	var prefixes = name_prefixes.get(species, ["Creature"])
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]

	return prefix + suffix

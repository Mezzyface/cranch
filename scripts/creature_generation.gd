# scripts/creature_generation.gd
class_name CreatureGenerator

# Species stat templates: [base_value, variance]
# Stats are generated as: base ± variance using normal distribution
# Aptitudes: High (35±10 = 25-45), Medium (25±8 = 17-33), Low (15±5 = 10-20)
# Max stat cap: 1000
const SPECIES_STATS = {
	GlobalEnums.Species.GUARD_ROBOT: {
		"strength": [35, 10],      # Tank - High strength
		"agility": [15, 5],        # Low agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.FIRE_PYROPE: {
		"strength": [35, 10],      # Strong elemental - High strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [15, 5]    # Low intelligence
	},
	GlobalEnums.Species.ILLUSIONARY_RACCOON: {
		"strength": [15, 5],       # Trickster - Low strength
		"agility": [35, 10],       # High agility
		"intelligence": [35, 10]   # High intelligence
	},
	GlobalEnums.Species.ORE_MUNCHER: {
		"strength": [35, 10],      # Powerful - High strength
		"agility": [15, 5],        # Low agility
		"intelligence": [15, 5]    # Low intelligence
	},
	GlobalEnums.Species.NEON_BAT: {
		"strength": [15, 5],       # Speedy - Low strength
		"agility": [35, 10],       # High agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.TOY_TROJAN: {
		"strength": [25, 8],       # Balanced fighter - Medium strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.ROBO: {
		"strength": [25, 8],       # Mechanical - Medium strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [35, 10]   # High intelligence
	},
	GlobalEnums.Species.FROSCOLA: {
		"strength": [25, 8],       # Balanced - Medium strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.GRIZZLY: {
		"strength": [35, 10],      # Beast - High strength
		"agility": [15, 5],        # Low agility
		"intelligence": [15, 5]    # Low intelligence
	},
	GlobalEnums.Species.BLAZIN_SPARKINSTONE_BUGS: {
		"strength": [35, 10],      # Elemental swarm - High strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [15, 5]    # Low intelligence
	},
	GlobalEnums.Species.STOPLIGHT_GHOST: {
		"strength": [15, 5],       # Ghost - Low strength
		"agility": [25, 8],        # Medium agility
		"intelligence": [35, 10]   # High intelligence
	},
	GlobalEnums.Species.HAUNTED_RIVER_ROCK: {
		"strength": [35, 10],      # Rock spirit - High strength
		"agility": [15, 5],        # Low agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.HEDGEHOG: {
		"strength": [25, 8],       # Spiky defender - Medium strength
		"agility": [35, 10],       # High agility
		"intelligence": [15, 5]    # Low intelligence
	},
	GlobalEnums.Species.DELINQUENT_CHICK: {
		"strength": [15, 5],       # Scrappy - Low strength
		"agility": [35, 10],       # High agility
		"intelligence": [25, 8]    # Medium intelligence
	},
	GlobalEnums.Species.OOZE_WASTE: {
		"strength": [25, 8],       # Toxic - Medium strength
		"agility": [15, 5],        # Low agility
		"intelligence": [35, 10]   # High intelligence
	},
	GlobalEnums.Species.KRIP: {
		"strength": [25, 8],       # Mysterious - Medium all
		"agility": [25, 8],        # Medium agility
		"intelligence": [25, 8]    # Medium intelligence (balanced)
	},
	GlobalEnums.Species.GRAVE_ROBBER_HUNTING_DOG: {
		"strength": [35, 10],      # Hunter - High strength
		"agility": [35, 10],       # High agility
		"intelligence": [15, 5]    # Low intelligence
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

	# Set lifespan based on species
	creature.birth_week = GameManager.current_week if GameManager else 1
	creature.max_lifespan = GlobalEnums.get_species_lifespan(species)

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

# scripts/creature_generation.gd
class_name CreatureGenerator

# Species stat templates: [base_value, variance]
# Stats are generated as: base ± variance using normal distribution
const SPECIES_STATS = {
	GlobalEnums.Species.SCUTTLEGUARD: {
		"strength": [12, 3],      # Tank - High strength
		"agility": [6, 2],        # Low agility
		"intelligence": [8, 2]    # Medium intelligence
	},
	GlobalEnums.Species.SLIME: {
		"strength": [8, 2],       # Balanced stats
		"agility": [8, 2],
		"intelligence": [8, 2]
	},
	GlobalEnums.Species.WIND_DANCER: {
		"strength": [6, 2],       # Mage - Low strength
		"agility": [12, 3],       # High agility
		"intelligence": [10, 2]   # High intelligence
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
		creature.strength = 10
		creature.agility = 10
		creature.intelligence = 10

	return creature

# Generate a stat value using normal distribution
# params: [base, variance] where stat = base ± variance
static func _generate_stat(params: Array) -> int:
	var base = params[0]
	var variance = params[1]

	# Use randfn for normal distribution (bell curve)
	# randfn(mean, deviation) - most values cluster around mean
	var value = randfn(base, variance / 2.0)  # Divide by 2 so most values stay within ± variance

	# Clamp to reasonable range (1-20 for now)
	return int(clamp(value, 1, 20))

# Generate a random name based on species
static func _generate_random_name(species: GlobalEnums.Species) -> String:
	# Name pools per species
	var name_prefixes = {
		GlobalEnums.Species.SCUTTLEGUARD: ["Crunch", "Shell", "Guard", "Scuttle", "Armor"],
		GlobalEnums.Species.SLIME: ["Goo", "Blob", "Squish", "Slip", "Ooze"],
		GlobalEnums.Species.WIND_DANCER: ["Breeze", "Gale", "Whisper", "Zephyr", "Swift"]
	}

	var suffixes = ["", "y", "ie", "ster", "ling", "let"]

	var prefixes = name_prefixes.get(species, ["Creature"])
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]

	return prefix + suffix

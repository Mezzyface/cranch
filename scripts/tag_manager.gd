# scripts/tag_manager.gd
class_name TagManager

# All loaded tags [tag_id -> TagResource]
static var all_tags: Dictionary = {}  # String -> TagResource

# Cached training tags for performance (populated during load_all_tags)
static var training_tags: Array[TagResource] = []

# Species to tag mapping [Species -> Array of tag_id strings]
static var species_tag_map: Dictionary = {
	GlobalEnums.Species.SCUTTLEGUARD: ["armored", "defensive", "sturdy"],
	GlobalEnums.Species.SLIME: ["adaptable", "amorphous", "regenerative"],
	GlobalEnums.Species.WIND_DANCER: ["swift", "magical", "aerial"]
}

# ===== TAG LOADING & LOOKUP =====

# Load all tag resources from resources/tags/ folder
static func load_all_tags():
	all_tags.clear()
	training_tags.clear()

	var tags_dir = "res://resources/tags/"
	var dir = DirAccess.open(tags_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var tag_path = tags_dir + file_name
				var tag = load(tag_path) as TagResource
				if tag and tag.tag_id != "":
					all_tags[tag.tag_id] = tag

					# Cache training tags for fast lookup
					if tag.is_category(GlobalEnums.TagCategory.TRAINING):
						training_tags.append(tag)

					print("Loaded tag: ", tag.tag_name, " (", tag.tag_id, ")")
				else:
					print("Failed to load tag or missing tag_id: ", tag_path)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		print("Failed to open tags directory: ", tags_dir)

	print("TagManager: Total tags loaded: ", all_tags.size(), " (", training_tags.size(), " training tags)")

# Get a tag by ID
static func get_tag(tag_id: String) -> TagResource:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	return all_tags.get(tag_id, null)

# Get species tags for a creature species
static func get_species_tags(species: GlobalEnums.Species) -> Array[TagResource]:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	var tags: Array[TagResource] = []

	if not species_tag_map.has(species):
		return tags

	var tag_ids = species_tag_map[species]
	for tag_id in tag_ids:
		var tag = get_tag(tag_id)
		if tag:
			tags.append(tag)

	return tags

# ===== TAG MUTATIONS (with signals) =====

# Add a tag to a creature (handles validation and signals)
# silent: if true, don't emit signal (used during initialization)
static func add_tag(creature: CreatureData, tag: TagResource, silent: bool = false):
	if not tag or not creature:
		return

	# Don't add duplicates
	if tag in creature.tags:
		return

	creature.tags.append(tag)

	if not silent:
		SignalBus.creature_tag_added.emit(creature, tag.tag_id)
		print("Creature ", creature.creature_name, " gained tag: ", tag.tag_name)

# Remove a tag from a creature (handles signals)
static func remove_tag(creature: CreatureData, tag: TagResource):
	if not tag or not creature:
		return

	if tag in creature.tags:
		creature.tags.erase(tag)
		SignalBus.creature_tag_removed.emit(creature, tag.tag_id)
		print("Creature ", creature.creature_name, " lost tag: ", tag.tag_name)

# Remove tag by ID
static func remove_tag_by_id(creature: CreatureData, tag_id: String):
	for tag in creature.tags:
		if tag and tag.tag_id == tag_id:
			remove_tag(creature, tag)
			break

# ===== TAG QUERIES & FILTERING =====

# Get all tags a creature has in a specific category
static func get_creature_tags_by_category(creature: CreatureData, category: GlobalEnums.TagCategory) -> Array[TagResource]:
	var filtered: Array[TagResource] = []
	for tag in creature.tags:
		if tag and tag.is_category(category):
			filtered.append(tag)
	return filtered

# Get all tags in a specific category (from all loaded tags)
static func get_all_tags_by_category(category: GlobalEnums.TagCategory) -> Array[TagResource]:
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	var filtered: Array[TagResource] = []
	for tag in all_tags.values():
		if tag and tag.is_category(category):
			filtered.append(tag)

	return filtered

# ===== TRAINING TAG LOGIC =====

# Check if creature qualifies for a training tag
static func check_training_qualification(creature: CreatureData, tag: TagResource) -> bool:
	if not tag.is_category(GlobalEnums.TagCategory.TRAINING):
		return false

	if tag.training_requirement.is_empty():
		return false

	var req_type = tag.training_requirement.get("type", "")

	match req_type:
		"stat_threshold":
			var stat_name = tag.training_requirement.get("stat", "")
			var threshold = tag.training_requirement.get("threshold", 0)
			var stat_value = creature.get(stat_name)
			return stat_value >= threshold

		"all_stats_threshold":
			var threshold = tag.training_requirement.get("threshold", 0)
			return (creature.strength >= threshold and
					creature.agility >= threshold and
					creature.intelligence >= threshold)

		"has_tag":
			var prereq_tag = tag.training_requirement.get("prerequisite_tag", "")
			return creature.has_tag(prereq_tag)

		"activity_count":
			# Future: Check activity history
			return false

	return false

# Check all training tags and auto-grant any creature qualifies for
static func auto_grant_training_tags(creature: CreatureData):
	# Lazy load if not loaded yet
	if all_tags.is_empty():
		load_all_tags()

	# Optimized: Only loop through training tags (cached during load)
	for tag in training_tags:
		# Skip if creature already has this tag
		if creature.has_tag(tag.tag_id):
			continue

		# Check if creature qualifies
		if check_training_qualification(creature, tag):
			add_tag(creature, tag)

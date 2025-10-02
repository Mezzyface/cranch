# scripts/generate_tags.gd
@tool
extends EditorScript

func _run():
	# Create tags directory if it doesn't exist
	var dir = DirAccess.open("res://resources/")
	if dir:
		if not dir.dir_exists("tags"):
			var err = dir.make_dir("tags")
			if err != OK:
				print("ERROR: Could not create tags directory: ", err)
				return
	else:
		print("ERROR: Could not open resources directory")
		return

	# Generate species tags
	generate_tag_armored()
	generate_tag_defensive()
	generate_tag_sturdy()
	generate_tag_adaptable()
	generate_tag_amorphous()
	generate_tag_regenerative()
	generate_tag_swift()
	generate_tag_magical()
	generate_tag_aerial()

	# Generate training tags
	generate_tag_scholar()
	generate_tag_battle_hardened()
	generate_tag_agile_expert()
	generate_tag_disciplined()

	print("Tag generation complete!")

# Species tags

func generate_tag_armored():
	var tag = TagResource.new()
	tag.tag_id = "armored"
	tag.tag_name = "Armored"
	tag.description = "Natural armor plating provides excellent defense"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES, GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.7, 0.7, 0.7)  # Gray
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "strength",
		"threshold": 20
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/armored.tres")
	if err != OK:
		print("ERROR saving armored.tres: ", err)
	else:
		print("✓ Created armored.tres")

func generate_tag_defensive():
	var tag = TagResource.new()
	tag.tag_id = "defensive"
	tag.tag_name = "Defensive"
	tag.description = "Excels at protecting and guarding"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.4, 0.6, 0.8)  # Blue
	var err = ResourceSaver.save(tag, "res://resources/tags/defensive.tres")
	if err != OK:
		print("ERROR saving defensive.tres: ", err)
	else:
		print("✓ Created defensive.tres")

func generate_tag_sturdy():
	var tag = TagResource.new()
	tag.tag_id = "sturdy"
	tag.tag_name = "Sturdy"
	tag.description = "Robust constitution and resilience"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.5, 0.4)  # Brown
	var err = ResourceSaver.save(tag, "res://resources/tags/sturdy.tres")
	if err != OK:
		print("ERROR saving sturdy.tres: ", err)
	else:
		print("✓ Created sturdy.tres")

func generate_tag_adaptable():
	var tag = TagResource.new()
	tag.tag_id = "adaptable"
	tag.tag_name = "Adaptable"
	tag.description = "Can adjust to various situations"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.5, 0.8, 0.5)  # Light green
	var err = ResourceSaver.save(tag, "res://resources/tags/adaptable.tres")
	if err != OK:
		print("ERROR saving adaptable.tres: ", err)
	else:
		print("✓ Created adaptable.tres")

func generate_tag_amorphous():
	var tag = TagResource.new()
	tag.tag_id = "amorphous"
	tag.tag_name = "Amorphous"
	tag.description = "No fixed form, can reshape body"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.9, 0.6)  # Bright green
	var err = ResourceSaver.save(tag, "res://resources/tags/amorphous.tres")
	if err != OK:
		print("ERROR saving amorphous.tres: ", err)
	else:
		print("✓ Created amorphous.tres")

func generate_tag_regenerative():
	var tag = TagResource.new()
	tag.tag_id = "regenerative"
	tag.tag_name = "Regenerative"
	tag.description = "Natural healing and recovery abilities"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.3, 0.9, 0.3)  # Green
	var err = ResourceSaver.save(tag, "res://resources/tags/regenerative.tres")
	if err != OK:
		print("ERROR saving regenerative.tres: ", err)
	else:
		print("✓ Created regenerative.tres")

func generate_tag_swift():
	var tag = TagResource.new()
	tag.tag_id = "swift"
	tag.tag_name = "Swift"
	tag.description = "Exceptional speed and agility"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES, GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.9, 0.3)  # Yellow
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "agility",
		"threshold": 20
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/swift.tres")
	if err != OK:
		print("ERROR saving swift.tres: ", err)
	else:
		print("✓ Created swift.tres")

func generate_tag_magical():
	var tag = TagResource.new()
	tag.tag_id = "magical"
	tag.tag_name = "Magical"
	tag.description = "Innate connection to magical energies"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.7, 0.4, 0.9)  # Purple
	var err = ResourceSaver.save(tag, "res://resources/tags/magical.tres")
	if err != OK:
		print("ERROR saving magical.tres: ", err)
	else:
		print("✓ Created magical.tres")

func generate_tag_aerial():
	var tag = TagResource.new()
	tag.tag_id = "aerial"
	tag.tag_name = "Aerial"
	tag.description = "Flight or aerial maneuvering capabilities"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.SPECIES]
	tag.categories = cats
	tag.color = Color(0.6, 0.8, 1.0)  # Sky blue
	var err = ResourceSaver.save(tag, "res://resources/tags/aerial.tres")
	if err != OK:
		print("ERROR saving aerial.tres: ", err)
	else:
		print("✓ Created aerial.tres")

# Training tags

func generate_tag_scholar():
	var tag = TagResource.new()
	tag.tag_id = "scholar"
	tag.tag_name = "Scholar"
	tag.description = "Highly intelligent and learned"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.4, 0.4, 0.9)  # Deep blue
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "intelligence",
		"threshold": 15
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/scholar.tres")
	if err != OK:
		print("ERROR saving scholar.tres: ", err)
	else:
		print("✓ Created scholar.tres")

func generate_tag_battle_hardened():
	var tag = TagResource.new()
	tag.tag_id = "battle_hardened"
	tag.tag_name = "Battle-Hardened"
	tag.description = "Experienced in combat and challenges"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.3, 0.3)  # Red
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "strength",
		"threshold": 18
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/battle_hardened.tres")
	if err != OK:
		print("ERROR saving battle_hardened.tres: ", err)
	else:
		print("✓ Created battle_hardened.tres")

func generate_tag_agile_expert():
	var tag = TagResource.new()
	tag.tag_id = "agile_expert"
	tag.tag_name = "Agile Expert"
	tag.description = "Master of speed and dexterity"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.9, 0.7, 0.2)  # Orange
	tag.training_requirement = {
		"type": "stat_threshold",
		"stat": "agility",
		"threshold": 18
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/agile_expert.tres")
	if err != OK:
		print("ERROR saving agile_expert.tres: ", err)
	else:
		print("✓ Created agile_expert.tres")

func generate_tag_disciplined():
	var tag = TagResource.new()
	tag.tag_id = "disciplined"
	tag.tag_name = "Disciplined"
	tag.description = "Well-rounded training across all areas"
	var cats: Array[GlobalEnums.TagCategory] = [GlobalEnums.TagCategory.TRAINING]
	tag.categories = cats
	tag.color = Color(0.6, 0.6, 0.6)  # Gray
	tag.training_requirement = {
		"type": "all_stats_threshold",
		"threshold": 12
	}
	var err = ResourceSaver.save(tag, "res://resources/tags/disciplined.tres")
	if err != OK:
		print("ERROR saving disciplined.tres: ", err)
	else:
		print("✓ Created disciplined.tres")

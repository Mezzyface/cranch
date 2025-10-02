# scripts/generate_facilities.gd
@tool
extends EditorScript

func _run():
	# Create facilities directory if it doesn't exist
	var dir = DirAccess.open("res://resources/")
	if dir:
		if not dir.dir_exists("facilities"):
			var err = dir.make_dir("facilities")
			if err != OK:
				print("ERROR: Could not create facilities directory: ", err)
				return
	else:
		print("ERROR: Could not open resources directory")
		return

	# Generate facilities
	generate_strength_training_facility()
	generate_agility_training_facility()
	generate_intelligence_training_facility()
	generate_balanced_training_facility()

	print("Facility generation complete!")

func generate_strength_training_facility():
	var facility = FacilityResource.new()
	facility.facility_name = "Strength Training Grounds"
	facility.description = "A rugged training area focused on building physical power"
	facility.max_creatures = 3

	var activity = StrengthTrainingActivity.new()
	activity.strength_gain = 5

	facility.activities.append(activity)

	var err = ResourceSaver.save(facility, "res://resources/facilities/strength_training.tres")
	if err != OK:
		print("ERROR saving strength_training.tres: ", err)
	else:
		print("✓ Created strength_training.tres")

func generate_agility_training_facility():
	var facility = FacilityResource.new()
	facility.facility_name = "Agility Training Course"
	facility.description = "An obstacle course designed to improve speed and dexterity"
	facility.max_creatures = 3

	var activity = AgilityTrainingActivity.new()
	activity.agility_gain = 5

	facility.activities.append(activity)

	var err = ResourceSaver.save(facility, "res://resources/facilities/agility_training.tres")
	if err != OK:
		print("ERROR saving agility_training.tres: ", err)
	else:
		print("✓ Created agility_training.tres")

func generate_intelligence_training_facility():
	var facility = FacilityResource.new()
	facility.facility_name = "Study Hall"
	facility.description = "A quiet library for mental development and learning"
	facility.max_creatures = 3

	var activity = IntelligenceTrainingActivity.new()
	activity.intelligence_gain = 5

	facility.activities.append(activity)

	var err = ResourceSaver.save(facility, "res://resources/facilities/intelligence_training.tres")
	if err != OK:
		print("ERROR saving intelligence_training.tres: ", err)
	else:
		print("✓ Created intelligence_training.tres")

func generate_balanced_training_facility():
	var facility = FacilityResource.new()
	facility.facility_name = "Balanced Training Dojo"
	facility.description = "A comprehensive training facility for all-around development"
	facility.max_creatures = 3

	var activity = BalancedTrainingActivity.new()
	activity.stat_gain = 3

	facility.activities.append(activity)

	var err = ResourceSaver.save(facility, "res://resources/facilities/balanced_training.tres")
	if err != OK:
		print("ERROR saving balanced_training.tres: ", err)
	else:
		print("✓ Created balanced_training.tres")

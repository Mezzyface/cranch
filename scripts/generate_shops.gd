@tool
extends EditorScript

# Run this script in Godot Editor: File > Run
# Creates shop resources in resources/shops/ folder

func _run():
	print("=== Generating Shop Resources ===")

	# Create shops directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("resources/shops"):
		dir.make_dir_recursive("resources/shops")
		print("Created resources/shops/ directory")

	# Generate shops
	_generate_food_market()
	_generate_creature_market()

	print("=== Shop Generation Complete ===")
	print("Check resources/shops/ folder for .tres files")

func _generate_food_market():
	var shop = ShopResource.new()
	shop.shop_name = "Food Market"
	shop.vendor_name = "Chef Gustav"
	shop.greeting = "Fresh food for your creatures! Keep them fed and trained!"

	# Basic Food entry
	var basic_food = ShopEntry.new()
	basic_food.entry_name = "Basic Food"
	basic_food.description = "Standard creature nutrition. One meal per training session."
	basic_food.entry_type = GlobalEnums.ShopEntryType.ITEM
	basic_food.cost = 10
	basic_food.stock = -1  # Unlimited
	basic_food.item_id = "food_basic"

	# Premium Food entry
	var premium_food = ShopEntry.new()
	premium_food.entry_name = "Premium Food"
	premium_food.description = "High-quality meal that provides +50% training bonus!"
	premium_food.entry_type = GlobalEnums.ShopEntryType.ITEM
	premium_food.cost = 25
	premium_food.stock = -1  # Unlimited
	premium_food.item_id = "food_premium"

	# Append to typed array (can't assign array directly)
	shop.entries.append(basic_food)
	shop.entries.append(premium_food)

	# Save resource
	var save_path = "res://resources/shops/food_market.tres"
	var result = ResourceSaver.save(shop, save_path)
	if result == OK:
		print("✓ Created: ", save_path)
	else:
		push_error("Failed to create: ", save_path)

func _generate_creature_market():
	var shop = ShopResource.new()
	shop.shop_name = "Creature Market"
	shop.vendor_name = "Breeder Bob"
	shop.greeting = "Quality creatures for discerning trainers!"

	# Guard Robot entry
	var guard_robot = ShopEntry.new()
	guard_robot.entry_name = "Guard Robot"
	guard_robot.description = "A sturdy mechanical guardian with high strength."
	guard_robot.entry_type = GlobalEnums.ShopEntryType.CREATURE
	guard_robot.creature_species = GlobalEnums.Species.GUARD_ROBOT
	guard_robot.cost = 300
	guard_robot.stock = -1  # Unlimited

	# Krip entry
	var krip = ShopEntry.new()
	krip.entry_name = "Krip"
	krip.description = "A perfectly balanced creature with mysterious origins."
	krip.entry_type = GlobalEnums.ShopEntryType.CREATURE
	krip.creature_species = GlobalEnums.Species.KRIP
	krip.cost = 250
	krip.stock = -1  # Unlimited

	# Neon Bat entry
	var neon_bat = ShopEntry.new()
	neon_bat.entry_name = "Neon Bat"
	neon_bat.description = "A swift glowing bat with incredible agility."
	neon_bat.entry_type = GlobalEnums.ShopEntryType.CREATURE
	neon_bat.creature_species = GlobalEnums.Species.NEON_BAT
	neon_bat.cost = 350
	neon_bat.stock = -1  # Unlimited

	# Fire Pyrope entry
	var fire_pyrope = ShopEntry.new()
	fire_pyrope.entry_name = "Fire Pyrope"
	fire_pyrope.description = "A powerful elemental creature wreathed in flames."
	fire_pyrope.entry_type = GlobalEnums.ShopEntryType.CREATURE
	fire_pyrope.creature_species = GlobalEnums.Species.FIRE_PYROPE
	fire_pyrope.cost = 400
	fire_pyrope.stock = -1  # Unlimited

	# Illusionary Raccoon entry
	var illusion_raccoon = ShopEntry.new()
	illusion_raccoon.entry_name = "Illusionary Raccoon"
	illusion_raccoon.description = "A cunning trickster with high intelligence."
	illusion_raccoon.entry_type = GlobalEnums.ShopEntryType.CREATURE
	illusion_raccoon.creature_species = GlobalEnums.Species.ILLUSIONARY_RACCOON
	illusion_raccoon.cost = 380
	illusion_raccoon.stock = -1  # Unlimited

	# Append to typed array (can't assign array directly)
	shop.entries.append(guard_robot)
	shop.entries.append(krip)
	shop.entries.append(neon_bat)
	shop.entries.append(fire_pyrope)
	shop.entries.append(illusion_raccoon)

	# Save resource
	var save_path = "res://resources/shops/creature_market.tres"
	var result = ResourceSaver.save(shop, save_path)
	if result == OK:
		print("✓ Created: ", save_path)
	else:
		push_error("Failed to create: ", save_path)

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

	# Scuttleguard entry
	var scuttleguard = ShopEntry.new()
	scuttleguard.entry_name = "Scuttleguard"
	scuttleguard.description = "A sturdy tank creature with high defense."
	scuttleguard.entry_type = GlobalEnums.ShopEntryType.CREATURE
	scuttleguard.creature_species = GlobalEnums.Species.SCUTTLEGUARD
	scuttleguard.cost = 150
	scuttleguard.stock = -1  # Unlimited

	# Slime entry
	var slime = ShopEntry.new()
	slime.entry_name = "Slime"
	slime.description = "A balanced creature that adapts to any situation."
	slime.entry_type = GlobalEnums.ShopEntryType.CREATURE
	slime.creature_species = GlobalEnums.Species.SLIME
	slime.cost = 100
	slime.stock = -1  # Unlimited

	# Wind Dancer entry
	var wind_dancer = ShopEntry.new()
	wind_dancer.entry_name = "Wind Dancer"
	wind_dancer.description = "A swift and intelligent aerial creature."
	wind_dancer.entry_type = GlobalEnums.ShopEntryType.CREATURE
	wind_dancer.creature_species = GlobalEnums.Species.WIND_DANCER
	wind_dancer.cost = 200
	wind_dancer.stock = -1  # Unlimited

	# Append to typed array (can't assign array directly)
	shop.entries.append(scuttleguard)
	shop.entries.append(slime)
	shop.entries.append(wind_dancer)

	# Save resource
	var save_path = "res://resources/shops/creature_market.tres"
	var result = ResourceSaver.save(shop, save_path)
	if result == OK:
		print("✓ Created: ", save_path)
	else:
		push_error("Failed to create: ", save_path)

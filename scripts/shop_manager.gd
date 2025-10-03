# scripts/shop_manager.gd
class_name ShopManager

# Handle shop purchases and validation
static func attempt_purchase(shop: ShopResource, entry_index: int) -> bool:
	if not shop or entry_index < 0 or entry_index >= shop.entries.size():
		push_error("Invalid shop or entry index")
		return false

	var entry = shop.entries[entry_index]

	# Check if item is in stock
	if not shop.can_purchase(entry_index):
		SignalBus.shop_purchase_failed.emit("Out of stock!")
		return false

	# Check if player has enough gold
	if not GameManager.player_data or GameManager.player_data.gold < entry.cost:
		SignalBus.shop_purchase_failed.emit("Not enough gold!")
		return false

	# Request gold deduction (negative amount = spend)
	SignalBus.gold_change_requested.emit(-entry.cost)

	# Process purchase based on entry type
	match entry.entry_type:
		GlobalEnums.ShopEntryType.CREATURE:
			_purchase_creature(entry)
		GlobalEnums.ShopEntryType.ITEM:
			_purchase_item(entry)
		GlobalEnums.ShopEntryType.SERVICE:
			_purchase_service(entry)

	# Update shop stock
	shop.purchase_item(entry_index)

	# Emit success signal
	SignalBus.shop_purchase_completed.emit(entry.entry_name, entry.cost)

	return true

static func _purchase_creature(entry: ShopEntry):
	# Generate creature directly and add to player array
	var creature = CreatureGenerator.generate_creature(entry.creature_species)
	GameManager.player_data.creatures.append(creature)
	SignalBus.creature_added.emit(creature)
	print("Purchased creature: %s (%s)" % [creature.creature_name, entry.entry_name])

static func _purchase_item(entry: ShopEntry):
	# Add item to inventory
	if not GameManager.inventory_manager.add_item(entry.item_id, 1):
		SignalBus.shop_purchase_failed.emit("Failed to add item to inventory")
		return

	print("Purchased item: ", entry.item_id)

static func _purchase_service(entry: ShopEntry):
	# TODO: Trigger service action (healing, training boost, etc)
	print("Purchased service: %s" % entry.entry_name)

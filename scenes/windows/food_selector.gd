class_name FoodSelectorHelper

static func open_food_selector(parent_node: Node, creature: CreatureData):
	var inventory_manager = GameManager.inventory_manager
	var player_inv = GameManager.player_data.inventory

	# Get all food items in inventory
	var food_items = inventory_manager.get_items_by_type(GlobalEnums.ItemType.FOOD)

	# Build items array
	var items: Array[Dictionary] = []
	for item_id in food_items:
		if player_inv.has(item_id) and player_inv[item_id] > 0:
			var item = inventory_manager.get_item_resource(item_id)
			if item:
				var quantity = player_inv[item_id]
				var description = "%s (x%d)" % [item.description if item.description else "", quantity]

				# Add stat boost info if applicable
				if item.stat_boost_multiplier != 1.0:
					description += "\n+%d%% training bonus" % int((item.stat_boost_multiplier - 1.0) * 100)

				items.append({
					"name": "%s (x%d)" % [item.item_name, quantity],
					"description": description,
					"data": item_id
				})

	# Create selector
	var selector = GenericSelector.create(
		"Select Food for %s" % creature.creature_name,
		items,
		func(item_id: String):
			GameManager.facility_manager.assign_food_to_creature(creature, item_id)
	)

	selector.empty_message = "No food in inventory!\nBuy food from shop (F6)"
	selector.open_signal = SignalBus.food_selection_requested

	parent_node.add_child(selector)

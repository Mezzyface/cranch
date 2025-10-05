class_name StoreSelectorHelper

static func open_store_selector(parent_node: Node):
	# Load all shops from resources/shops/
	var shops = _load_shops()

	if shops.is_empty():
		push_error("No shops found in resources/shops/")
		return

	# Convert shops to selector items
	var items: Array[Dictionary] = []
	for shop_data in shops:
		var shop: ShopResource = shop_data.resource
		items.append({
			"name": shop.shop_name,
			"description": shop.greeting,
			"data": shop
		})

	# Create selector
	var selector = GenericSelector.create(
		"Select a Store",
		items,
		func(shop: ShopResource):
			_open_shop(parent_node, shop)
	)

	# Set signals
	selector.open_signal = SignalBus.shop_selector_opened
	selector.close_signal = SignalBus.shop_selector_closed
	selector.empty_message = "No shops available"

	parent_node.add_child(selector)

static func _load_shops() -> Array[Dictionary]:
	var shops: Array[Dictionary] = []
	var shops_path = "res://resources/shops/"
	var dir = DirAccess.open(shops_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var shop_path = shops_path + file_name
				var shop: ShopResource = load(shop_path)
				if shop:
					shops.append({
						"resource": shop,
						"path": shop_path
					})
					print("Loaded shop: ", shop.shop_name)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Failed to open shops directory: " + shops_path)

	return shops

static func _open_shop(parent_node: Node, shop: ShopResource):
	var shop_window_scene = preload("res://scenes/windows/shop_window.tscn")
	var shop_window = shop_window_scene.instantiate()
	parent_node.add_child(shop_window)
	shop_window.setup(shop)

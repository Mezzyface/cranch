class_name InventoryManager

# Reference to player data
var player_data: PlayerData

# Item database - loaded from resources/items/
var _item_database: Dictionary = {}  # {item_id: ItemResource}

func _init(p_player_data: PlayerData):
	player_data = p_player_data
	_load_item_database()

# Load all item resources from resources/items/ folder
func _load_item_database():
	var items_path = "res://resources/items/"
	var dir = DirAccess.open(items_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var item_path = items_path + file_name
				var item: ItemResource = load(item_path)
				if item:
					var item_id = file_name.replace(".tres", "")
					_item_database[item_id] = item
					print("Loaded item: ", item_id)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Failed to open items directory: " + items_path)

# Add item to inventory
func add_item(item_id: String, quantity: int = 1) -> bool:
	if not _item_database.has(item_id):
		push_error("Item not found in database: " + item_id)
		return false

	var item: ItemResource = _item_database[item_id]

	if not item.is_stackable and player_data.inventory.has(item_id):
		push_error("Cannot add non-stackable item that already exists")
		return false

	# Add to inventory
	if player_data.inventory.has(item_id):
		var new_quantity = player_data.inventory[item_id] + quantity
		if item.is_stackable and new_quantity > item.max_stack_size:
			push_error("Cannot exceed max stack size")
			return false
		player_data.inventory[item_id] = new_quantity
	else:
		player_data.inventory[item_id] = quantity

	SignalBus.item_added.emit(item_id, quantity)
	return true

# Remove item from inventory
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not player_data.inventory.has(item_id):
		return false

	if player_data.inventory[item_id] < quantity:
		return false

	player_data.inventory[item_id] -= quantity

	# Remove from dict if quantity reaches 0
	if player_data.inventory[item_id] <= 0:
		player_data.inventory.erase(item_id)

	SignalBus.item_removed.emit(item_id, quantity)
	return true

# Check if player has enough of an item
func has_item(item_id: String, quantity: int = 1) -> bool:
	return player_data.inventory.get(item_id, 0) >= quantity

# Get item quantity
func get_item_quantity(item_id: String) -> int:
	return player_data.inventory.get(item_id, 0)

# Get item resource from database
func get_item_resource(item_id: String) -> ItemResource:
	return _item_database.get(item_id)

# Get all items of a specific type
func get_items_by_type(item_type: GlobalEnums.ItemType) -> Array[String]:
	var result: Array[String] = []
	for item_id in _item_database.keys():
		var item: ItemResource = _item_database[item_id]
		if item.item_type == item_type:
			result.append(item_id)
	return result

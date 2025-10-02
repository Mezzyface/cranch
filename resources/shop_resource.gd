# resources/shop_resource.gd
extends Resource
class_name ShopResource

@export var shop_name: String = "General Shop"
@export var vendor_name: String = "Shopkeeper"
@export var greeting: String = "Welcome to my shop!"

# Array of ShopEntry (each contains ItemResource + price + stock)
@export var entries: Array[ShopEntry] = []

# Track current stock for items with limited quantity
var current_stock: Dictionary = {}  # entry_index -> remaining stock

func _init():
	_initialize_stock()

func _initialize_stock():
	current_stock.clear()
	for i in range(entries.size()):
		if entries[i].stock > 0:
			current_stock[i] = entries[i].stock

func get_remaining_stock(entry_index: int) -> int:
	var entry = entries[entry_index]
	if entry.stock == -1:
		return -1  # Unlimited
	return current_stock.get(entry_index, 0)

func can_purchase(entry_index: int) -> bool:
	if entry_index < 0 or entry_index >= entries.size():
		return false
	var remaining = get_remaining_stock(entry_index)
	return remaining == -1 or remaining > 0

func purchase_item(entry_index: int) -> bool:
	if not can_purchase(entry_index):
		return false
	var entry = entries[entry_index]
	if entry.stock > 0:
		current_stock[entry_index] -= 1
	return true

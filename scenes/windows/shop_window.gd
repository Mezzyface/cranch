# scenes/windows/shop_window.gd
extends Panel

@onready var shop_name_label = $Panel/ShopNameLabel
@onready var greeting_label = $MarginContainer/VBoxContainer/GreetingLabel
@onready var item_list_container = $MarginContainer/VBoxContainer/ItemList/VBoxContainer
@onready var gold_label = $PanelContainer/Footer/GoldLabel
@onready var close_button = $CloseButton

var current_shop: ShopResource

# Preload shop item entry scene
const SHOP_ITEM_ENTRY = preload("res://scenes/ui/shop_item_entry.tscn")

func _ready():
	close_button.pressed.connect(_on_close_pressed)

	# Connect to signals
	SignalBus.gold_changed.connect(_update_gold_display)
	SignalBus.shop_purchase_completed.connect(_on_purchase_completed)
	SignalBus.shop_purchase_failed.connect(_on_purchase_failed)

	# Start hidden
	hide()

func setup(shop: ShopResource):
	current_shop = shop

	# Set header
	shop_name_label.text = shop.shop_name
	greeting_label.text = shop.greeting

	# Populate item list
	_populate_items()

	# Update gold display
	_update_gold_display(GameManager.player_data.gold if GameManager.player_data else 0)

	# Show the shop
	show()

	# Emit signal
	SignalBus.shop_opened.emit(shop)

func _populate_items():
	# Clear existing items
	for child in item_list_container.get_children():
		child.queue_free()

	# Add shop entries
	for i in range(current_shop.entries.size()):
		var shop_entry = current_shop.entries[i]
		var entry = SHOP_ITEM_ENTRY.instantiate()
		item_list_container.add_child(entry)
		entry.setup(shop_entry, i, current_shop)
		entry.purchase_requested.connect(_on_purchase_requested)

func _on_purchase_requested(entry_index: int):
	ShopManager.attempt_purchase(current_shop, entry_index)

func _on_purchase_completed(item_name: String, cost: int):
	print("Purchase successful: %s for %d gold" % [item_name, cost])
	# Refresh item list to update stock displays
	_populate_items()

func _on_purchase_failed(reason: String):
	print("Purchase failed: %s" % reason)
	# TODO: Show visual feedback (popup, shake, flash red, etc)

func _update_gold_display(gold_amount: int):
	gold_label.text = "%d" % gold_amount

func _on_close_pressed():
	SignalBus.shop_closed.emit()
	hide()
	# Optional: queue_free() if you want to destroy it completely
	# For now just hiding so it can be reused

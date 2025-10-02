# scenes/ui/shop_item_entry.gd
extends PanelContainer

signal purchase_requested(item_index: int)

@onready var icon_rect = $HBoxContainer/IconRect
@onready var item_name_label = $HBoxContainer/InfoVBox/ItemNameLabel
@onready var description_label = $HBoxContainer/InfoVBox/DescriptionLabel
@onready var stock_label = $HBoxContainer/InfoVBox/StockLabel
@onready var buy_button = $HBoxContainer/BuyButton

var shop_entry: ShopEntry
var entry_index: int
var shop: ShopResource

func setup(entry: ShopEntry, index: int, shop_ref: ShopResource):
	shop_entry = entry
	entry_index = index
	shop = shop_ref

	# Wait for nodes to be ready if needed
	if not is_node_ready():
		await ready

	# Set display from entry data
	item_name_label.text = entry.entry_name
	description_label.text = entry.description
	buy_button.text = "Buy (%dg)" % entry.cost

	if entry.icon_texture:
		icon_rect.texture = entry.icon_texture

	# Update stock display
	_update_stock_display()

	# Connect button (only once)
	if not buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.connect(_on_buy_pressed)

func _update_stock_display():
	var remaining = shop.get_remaining_stock(entry_index)

	if remaining == -1:
		stock_label.text = "Stock: Unlimited"
	else:
		stock_label.text = "Stock: %d" % remaining
		if remaining == 0:
			buy_button.disabled = true
			stock_label.text = "SOLD OUT"

func _on_buy_pressed():
	purchase_requested.emit(entry_index)

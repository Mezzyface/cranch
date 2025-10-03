extends Panel

var target_creature: CreatureData

@onready var title_label = $VBoxContainer/Label
@onready var food_list = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var cancel_button = $VBoxContainer/CancelButton

func _ready():
	cancel_button.pressed.connect(_on_cancel)
	populate_food_list()

	# Center on screen
	position = (get_viewport_rect().size - size) / 2

func setup(creature: CreatureData):
	target_creature = creature
	if title_label:
		title_label.text = "Select Food for %s" % creature.creature_name

func populate_food_list():
	# Clear existing
	for child in food_list.get_children():
		child.queue_free()

	var inventory_manager = GameManager.inventory_manager
	var player_inv = GameManager.player_data.inventory

	# Get all food items in inventory
	var food_items = inventory_manager.get_items_by_type(GlobalEnums.ItemType.FOOD)

	var has_food = false
	for item_id in food_items:
		if player_inv.has(item_id) and player_inv[item_id] > 0:
			has_food = true
			_create_food_button(item_id, player_inv[item_id])

	if not has_food:
		var label = Label.new()
		label.text = "No food in inventory!\nBuy food from shop (F6)"
		food_list.add_child(label)

func _create_food_button(item_id: String, quantity: int):
	var item = GameManager.inventory_manager.get_item_resource(item_id)
	if not item:
		return

	var hbox = HBoxContainer.new()

	var button = Button.new()
	button.text = "%s (x%d)" % [item.item_name, quantity]
	button.custom_minimum_size.x = 300
	button.pressed.connect(_on_food_selected.bind(item_id))
	hbox.add_child(button)

	# Show stat multiplier if not 1.0
	if item.stat_boost_multiplier != 1.0:
		var boost_label = Label.new()
		boost_label.text = "+%d%% bonus" % int((item.stat_boost_multiplier - 1.0) * 100)
		boost_label.modulate = Color.GREEN
		hbox.add_child(boost_label)

	food_list.add_child(hbox)

func _on_food_selected(item_id: String):
	# Assign food to creature
	GameManager.facility_manager.assign_food_to_creature(target_creature, item_id)
	queue_free()

func _on_cancel():
	queue_free()

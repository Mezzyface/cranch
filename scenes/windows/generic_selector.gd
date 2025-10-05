extends PanelContainer
class_name GenericSelector

# Configuration
var title: String = "Select an Option"
var empty_message: String = "No options available"

# Item data structure: Array[Dictionary]
# Each dictionary should have:
#   - "name": String (button text)
#   - "description": String (optional, subtitle text)
#   - "data": Variant (passed to callback when selected)
var items: Array[Dictionary] = []

# Callback when item selected: func(data: Variant)
var on_item_selected: Callable

# Optional signal to emit when opened
var open_signal: Signal
var close_signal: Signal

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var item_list = $MarginContainer/VBoxContainer/ScrollContainer/ItemList
@onready var close_button = $MarginContainer/VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)

	# Set title
	title_label.text = title

	# Populate items
	_populate_list()

	# Center on screen
	position = (get_viewport_rect().size - size) / 2

	# Emit open signal if provided
	if open_signal:
		open_signal.emit()

func _populate_list():
	# Clear existing
	for child in item_list.get_children():
		child.queue_free()

	if items.is_empty():
		var label = Label.new()
		label.text = empty_message
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(label)
		return

	# Create button for each item
	for item in items:
		_create_item_button(item)

func _create_item_button(item: Dictionary):
	var vbox = VBoxContainer.new()

	var button = Button.new()
	button.text = item.get("name", "Unnamed")
	button.custom_minimum_size = Vector2(360, 60)
	button.pressed.connect(_on_item_selected.bind(item.get("data")))
	vbox.add_child(button)

	# Optional description
	if item.has("description") and not item.description.is_empty():
		var desc_label = Label.new()
		desc_label.text = item.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size.x = 360
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(desc_label)

	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	item_list.add_child(vbox)

func _on_item_selected(data: Variant):
	# Call callback if provided
	if on_item_selected:
		on_item_selected.call(data)

	# Close selector
	queue_free()

func _on_close_pressed():
	# Emit close signal if provided
	if close_signal:
		close_signal.emit()
	queue_free()

# Static helper to create and configure a selector
static func create(p_title: String, p_items: Array[Dictionary], p_callback: Callable) -> GenericSelector:
	var selector_scene = preload("res://scenes/windows/generic_selector.tscn")
	var selector = selector_scene.instantiate()
	selector.title = p_title
	selector.items = p_items
	selector.on_item_selected = p_callback
	return selector

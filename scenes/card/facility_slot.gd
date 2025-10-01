# scenes/ui/facility_slot.gd
extends Panel
class_name FacilitySlot

@export var slot_index: int = 0
@export var slot_name: String = "Facility Slot"

var current_facility_card: FacilityCard = null
var is_hover: bool = false

signal facility_placed(facility_card: FacilityCard, slot: FacilitySlot)
signal facility_removed(facility_card: FacilityCard, slot: FacilitySlot)

func _ready():
	custom_minimum_size = Vector2(320, 420)  # Slightly larger than facility cards
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Visual setup for empty slot
	_setup_empty_visual()

	# Setup drop handling with DragDropComponent
	_setup_drop_zone()

func _setup_empty_visual():
	# Add a dashed border or background to show it's an empty slot
	modulate = Color(0.5, 0.5, 0.5, 0.8)

	# Add placeholder text
	var label = Label.new()
	label.text = slot_name + "\n[Drop Facility Here]"
	label.add_theme_font_size_override("font_size", 14)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.name = "PlaceholderLabel"
	add_child(label)

func _on_mouse_entered():
	is_hover = true
	if not current_facility_card:
		modulate = Color(0.7, 0.7, 0.7, 0.9)

func _on_mouse_exited():
	is_hover = false
	if not current_facility_card:
		modulate = Color(0.5, 0.5, 0.5, 0.8)

func can_accept_facility(facility_card: FacilityCard) -> bool:
	# Can accept if empty or if we allow swapping
	return current_facility_card == null

func place_facility(facility_card: FacilityCard):
	# Remove from previous slot if it has one
	if facility_card.current_slot and facility_card.current_slot != self:
		facility_card.current_slot.remove_facility()

	# Place in this slot
	current_facility_card = facility_card
	facility_card.current_slot = self

	# Reparent the facility card to this slot
	if facility_card.get_parent():
		facility_card.get_parent().remove_child(facility_card)
	add_child(facility_card)
	facility_card.position = Vector2.ZERO

	# Hide placeholder
	if has_node("PlaceholderLabel"):
		$PlaceholderLabel.hide()

	# Reset modulate
	modulate = Color.WHITE

	facility_placed.emit(facility_card, self)

func remove_facility():
	if current_facility_card:
		var card = current_facility_card
		current_facility_card = null
		card.current_slot = null

		# Show placeholder again
		if has_node("PlaceholderLabel"):
			$PlaceholderLabel.show()

		_setup_empty_visual()
		facility_removed.emit(card, self)

func _setup_drop_zone():
	# Create drop zone for facility cards
	var drop_zone = DragDropComponent.new()
	drop_zone.name = "FacilitySlotDropZone"
	drop_zone.drag_type = DragDropComponent.DragType.FACILITY_CARD
	drop_zone.can_accept_drops = true
	drop_zone.can_drag = false  # Drop-only zone
	drop_zone.mouse_filter_mode = Control.MOUSE_FILTER_STOP
	drop_zone.z_index = 100

	# Fill the entire slot
	drop_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_zone.set_offsets_preset(Control.PRESET_FULL_RECT)

	# Custom validation
	drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
		if data.has("facility_card"):
			return can_accept_facility(data.facility_card)
		return false

	# Connect drop signal
	drop_zone.drop_received.connect(_on_facility_dropped)

	add_child(drop_zone)

func _on_facility_dropped(data: Dictionary):
	if data.has("facility_card"):
		place_facility(data.facility_card)

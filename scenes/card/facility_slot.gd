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

func _can_drop_data(_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("facility_card") and can_accept_facility(data.facility_card)

func _drop_data(_position: Vector2, data) -> void:
	if data.has("facility_card"):
		place_facility(data.facility_card)

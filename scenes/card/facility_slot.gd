# scenes/ui/facility_slot.gd
extends Panel
class_name FacilitySlot

@export var slot_index: int = 0
@export var slot_name: String = "Facility Slot"
@export var is_locked: bool = false
@export var unlock_cost: int = 100
@export var unlock_facility: FacilityResource = null  # Facility to place when unlocked

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

	if is_locked:
		_create_locked_overlay()
		
	# Setup drop handling with DragDropComponent
	if not is_locked:
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
	# Check if slot is locked
	if is_locked:
		print("Cannot place facility - slot is locked")
		return false
		
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

func _create_locked_overlay():
	# Create semi-transparent overlay
	var overlay = ColorRect.new()
	overlay.name = "LockedOverlay"
	overlay.color = Color(0, 0, 0, 0.7)  # Dark overlay
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block interactions
	add_child(overlay)

	# Fill the entire slot
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)

	# Create lock icon (using a Label for now - can be replaced with texture later)
	var lock_icon = Label.new()
	lock_icon.text = "🔒"
	lock_icon.add_theme_font_size_override("font_size", 64)
	lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(lock_icon)
	lock_icon.set_anchors_preset(Control.PRESET_CENTER)

	# Create cost label
	var cost_label = Label.new()
	cost_label.text = "Unlock: %d gold" % unlock_cost
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(cost_label)
	cost_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cost_label.position.y = -40  # Offset from bottom

	# Make overlay clickable
	overlay.gui_input.connect(_on_locked_overlay_clicked)

func _on_locked_overlay_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attempt_unlock()

func attempt_unlock():
	if not is_locked:
		return

	# Check if player has enough gold
	if not GameManager.player_data or GameManager.player_data.gold < unlock_cost:
		print("Not enough gold to unlock slot %d (need %d)" % [slot_index, unlock_cost])
		# TODO: Show feedback to player (shake effect, red flash, etc)
		return

	# Deduct gold
	GameManager.player_data.gold -= unlock_cost
	SignalBus.gold_changed.emit(GameManager.player_data.gold)

	# Unlock the slot
	is_locked = false

	# Remove locked overlay
	var overlay = get_node_or_null("LockedOverlay")
	if overlay:
		overlay.queue_free()

	_setup_drop_zone()

	# Auto-place facility if one is assigned
	if unlock_facility:
		var card_scene = preload("res://scenes/card/facility_card.tscn")
		var card = card_scene.instantiate()
		card.facility_resource = unlock_facility
		card.add_to_group("facility_cards")
		place_facility(card)
		print("Auto-placed facility: ", unlock_facility.facility_name)

	# Emit signal
	SignalBus.facility_slot_unlocked.emit(slot_index, unlock_cost)

	print("Unlocked facility slot %d for %d gold" % [slot_index, unlock_cost])

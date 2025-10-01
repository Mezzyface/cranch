# scenes/ui/facility_card.gd
extends Panel
class_name FacilityCard

@export var facility_resource: FacilityResource

@onready var name_label: Label = $VBoxContainer/Panel/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var activities_list: RichTextLabel = $VBoxContainer/MarginContainer/VBoxContainer/ActivitiesList
@onready var creature_slots: HBoxContainer = $VBoxContainer/MarginContainer/VBoxContainer/CreatureSlots
var current_slot: FacilitySlot = null
var assigned_creatures: Array[CreatureData] = []
var is_hover: bool = false

const DragDropComponent = preload("res://scripts/drag_drop_component.gd")

func _ready():
	if facility_resource:
		setup_facility(facility_resource)

	if creature_slots:
		creature_slots.mouse_filter = Control.MOUSE_FILTER_PASS

	# Make this a drop target
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_setup_facility_card_dragging()  # Enable facility card dragging (must be before slots are populated)

func setup_facility(facility: FacilityResource):
	facility_resource = facility
	name_label.text = facility.facility_name

	# Display activities
	activities_list.clear()
	for activity in facility.activities:
		activities_list.append_text("• " + activity.activity_name + "\n")

	# Create creature slots
	for i in range(facility.max_creatures):
		var slot_container = Control.new()
		slot_container.custom_minimum_size = Vector2(60, 60)  # Size for creature sprite
		slot_container.name = "Slot_" + str(i)
		slot_container.mouse_filter = Control.MOUSE_FILTER_PASS

		# Add empty label as placeholder
		var slot_label = Label.new()
		slot_label.text = "[Empty]"
		slot_label.modulate = Color(0.5, 0.5, 0.5)
		slot_label.add_theme_font_size_override("font_size", 10)
		slot_label.name = "Label"
		slot_container.add_child(slot_label)

		creature_slots.add_child(slot_container)

		var slot_bg = Panel.new()
		slot_bg.custom_minimum_size = Vector2(60, 60)
		slot_bg.modulate = Color(0.2, 0.2, 0.2, 0.5)  # Semi-transparent dark
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
		slot_container.add_child(slot_bg)
		slot_bg.show_behind_parent = true

func _on_mouse_entered():
	is_hover = true
	modulate = Color(1.1, 1.1, 1.1)  # Slight highlight on hover

func _on_mouse_exited():
	is_hover = false
	modulate = Color.WHITE

func can_accept_creature(creature: CreatureData) -> bool:
	return assigned_creatures.size() < facility_resource.max_creatures

func remove_creature(creature: CreatureData):
	var index = assigned_creatures.find(creature)
	if index != -1:
		assigned_creatures.erase(creature)
		# Update visual slots
		update_slots()

func remove_creature_by_sprite(sprite: AnimatedSprite2D):
	# Find which creature this sprite belongs to and remove it
	# We need to find the slot index based on the sprite
	for i in range(creature_slots.get_child_count()):
		var slot_container = creature_slots.get_child(i)
		for child in slot_container.get_children():
			if child == sprite:
				# Found it! Remove the creature at this index
				if i < assigned_creatures.size():
					var creature = assigned_creatures[i]
					assigned_creatures.remove_at(i)

					# Unregister from FacilityManager
					if GameManager.facility_manager:
						GameManager.facility_manager.unregister_assignment(creature, facility_resource)

					# Emit signal
					SignalBus.facility_unassigned.emit(creature, facility_resource)

					update_slots()
					return

func assign_creature(creature: CreatureData, source_node: Node = null):
	if can_accept_creature(creature):
		assigned_creatures.append(creature)

		# Add the creature sprite to the card
		_add_creature_sprite(creature, assigned_creatures.size() - 1)

		# Register with FacilityManager through GameManager
		if GameManager.facility_manager:
			GameManager.facility_manager.register_assignment(creature, facility_resource)

		# Remove the source creature from the world
		# Only free if it's a CreatureDisplay (from world)
		if source_node and source_node is CreatureDisplay:
			source_node.queue_free()

		# Emit signal
		SignalBus.facility_assigned.emit(creature, facility_resource)
		return true
	return false

func assign_creature_from_drag(creature: CreatureData, drag_data: Dictionary):
	"""Assign a creature from drag data, handling removal from source facility if needed"""
	if can_accept_creature(creature):
		assigned_creatures.append(creature)

		# Add the creature sprite to the card
		_add_creature_sprite(creature, assigned_creatures.size() - 1)

		# Register with FacilityManager through GameManager
		if GameManager.facility_manager:
			GameManager.facility_manager.register_assignment(creature, facility_resource)

		# Handle removing from source
		var source_node = drag_data.get("source_node")
		if source_node:
			if source_node is CreatureDisplay:
				# From world - free the creature display
				source_node.queue_free()
			elif source_node is AnimatedSprite2D:
				# From another facility - use the facility_card reference in drag data
				var old_facility = drag_data.get("facility_card")
				if old_facility and old_facility is FacilityCard and old_facility != self:
					old_facility.remove_creature_by_sprite(source_node)

		# Emit signal
		SignalBus.facility_assigned.emit(creature, facility_resource)
		return true
	return false

func _add_creature_sprite(creature: CreatureData, slot_index: int):
	# Get the slot container for this index
	if slot_index >= creature_slots.get_child_count():
		return

	var slot = creature_slots.get_child(slot_index)

	# Clear existing label content
	if slot is Label:
		slot.text = ""
		slot.hide()

	if slot.get_node("Label") is Label:
		var label = slot.get_node("Label")
		label.text = creature.creature_name
		label.modulate = Color.WHITE  # Ensure not grayed out
		label.add_theme_font_size_override("font_size", 10)

	# Create animated sprite for the creature
	var sprite = AnimatedSprite2D.new()
	sprite.name = "CreatureSprite_" + str(slot_index)

	# Get sprite frames from GlobalEnums
	var sprite_frames = GlobalEnums.get_sprite_frames_for_species(creature.species)
	if sprite_frames:
		sprite.sprite_frames = sprite_frames
		sprite.play("idle")  # Play idle animation
		
	# Position the sprite in the slot container
	var slot_container = creature_slots.get_child(slot_index)
	slot_container.add_child(sprite)
	sprite.position = Vector2(30, 30)  # Center in the 60x60 slot

	# Create drag component for this creature - layer 2 (on top of facility drag)
	var drag_component = DragDropComponent.new()
	drag_component.name = "CreatureDrag_" + str(slot_index)
	drag_component.drag_type = DragDropComponent.DragType.CREATURE
	drag_component.drag_data_source = sprite
	drag_component.mouse_filter_mode = Control.MOUSE_FILTER_STOP
	drag_component.z_index = 101  # On top of FacilityDrag

	# Position over the slot area (get slot's global position relative to card)
	var slot_global_pos = slot_container.global_position
	var card_global_pos = global_position
	var relative_pos = slot_global_pos - card_global_pos

	drag_component.position = relative_pos
	drag_component.size = slot_container.size

	# Store reference to creature and facility
	drag_component.custom_drag_data = {
		"creature": creature,
		"facility_card": self,
		"sprite": sprite
	}

	# Connect signals to handle drag events
	drag_component.drag_started.connect(func(_data):
		sprite.visible = false
	)

	drag_component.drag_ended.connect(func(_successful):
		if sprite and is_instance_valid(sprite):
			sprite.visible = true
	)

	# Add as sibling to FacilityDrag (as child of card, not slot)
	add_child(drag_component)

func update_slots():
	# First, remove all creature drag components from card level
	for child in get_children():
		if child.name.begins_with("CreatureDrag_"):
			child.queue_free()

	# Clear creature sprites from slots
	for i in range(creature_slots.get_child_count()):
		var slot_container = creature_slots.get_child(i)

		for child in slot_container.get_children():
			if child is AnimatedSprite2D:
				child.queue_free()

		if i < assigned_creatures.size():
			# Show the label with creature name
			for child in slot_container.get_children():
				if child is Label:
					child.show()
					child.text = assigned_creatures[i].creature_name
					child.modulate = Color.WHITE  # Not grayed out
					child.add_theme_font_size_override("font_size", 10)  # Maintain small font

			# Add fresh sprite and drag component
			_add_creature_sprite(assigned_creatures[i], i)
		else:
			# Show empty label
			for child in slot_container.get_children():
				if child is Label:
					child.show()
					child.text = "[Empty]"
					child.modulate = Color(0.5, 0.5, 0.5)  # Gray out empty slots
					child.add_theme_font_size_override("font_size", 10)  # Maintain small font

# Visual feedback during drag hover
func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		# Something is being dragged (might not be over us yet)
		pass
	elif what == NOTIFICATION_DRAG_END:
		# Drag operation ended
		modulate = Color.WHITE if not is_hover else Color(1.1, 1.1, 1.1)

func _setup_facility_card_dragging():
	# Create drag component for facility card - layer 1 (base drag layer)
	var facility_drag = DragDropComponent.new()
	facility_drag.name = "FacilityDrag"
	facility_drag.drag_type = DragDropComponent.DragType.FACILITY_CARD
	facility_drag.drag_data_source = self
	facility_drag.can_accept_drops = true
	facility_drag.mouse_filter_mode = Control.MOUSE_FILTER_STOP
	facility_drag.hide_on_drag = false
	facility_drag.z_index = 100  # On top of all visual elements

	# Fill the entire card
	facility_drag.set_anchors_preset(Control.PRESET_FULL_RECT)
	facility_drag.set_offsets_preset(Control.PRESET_FULL_RECT)

	# Custom drop validation for creatures
	facility_drag.custom_can_drop_callback = func(data: Dictionary) -> bool:
		if data.has("creature"):
			return can_accept_creature(data.get("creature"))
		return false

	# Connect drop signal
	facility_drag.drop_received.connect(_on_creature_dropped)

	# Add to card
	add_child(facility_drag)

func _on_creature_dropped(data: Dictionary):
	if data.has("creature"):
		var creature = data.get("creature")
		if can_accept_creature(creature):
			assign_creature_from_drag(creature, data)

# scenes/ui/facility_card.gd
extends Panel
class_name FacilityCard

@export var facility_resource: FacilityResource

@onready var name_label: Label = $VBoxContainer/Panel/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var activities_list: RichTextLabel = $VBoxContainer/MarginContainer/VBoxContainer/ActivitiesList
@onready var creature_slots: HBoxContainer = $VBoxContainer/MarginContainer/VBoxContainer/CreatureSlots
@onready var drop_area: Control = $DropArea

var current_slot: FacilitySlot = null
var is_being_dragged: bool = false
var drag_offset: Vector2
var assigned_creatures: Array[CreatureData] = []
var is_hover: bool = false

const FacilityCreatureDrag = preload("res://scripts/facility_creature_drag.gd")

func _ready():
	if facility_resource:
		setup_facility(facility_resource)
	
	if creature_slots:
		creature_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make this a drop target
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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
		slot_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func assign_creature(creature: CreatureData, source_node: Node = null):
	if can_accept_creature(creature):
		assigned_creatures.append(creature)

		# Add the creature sprite to the card
		_add_creature_sprite(creature, assigned_creatures.size() - 1)

		# Register with FacilityManager through GameManager
		if GameManager.facility_manager:
			GameManager.facility_manager.register_assignment(creature, facility_resource)

		# Remove the source creature from the world
		if source_node:
			source_node.queue_free()

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
		print(creature.creature_name)
		slot.get_node("Label").text = creature.creature_name

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
	
	# ADD: Create a control node to handle drag for this creature
	var drag_control = Control.new()
	drag_control.name = "DragControl"
	drag_control.custom_minimum_size = Vector2(60, 60)
	drag_control.position = Vector2(-30, -30)  # Center on sprite
	drag_control.mouse_filter = Control.MOUSE_FILTER_PASS  # Ensure it receives event
	
	slot_container.add_child(drag_control)

	# ADD: Set up the drag control to handle this specific creature
	var drag_script = FacilityCreatureDrag
	drag_control.set_script(drag_script)
	drag_control.creature_data = creature
	drag_control.facility_card = self


	
func update_slots():
	for i in range(creature_slots.get_child_count()):
		var slot_container = creature_slots.get_child(i)

		if i < assigned_creatures.size():
			# Hide the empty label if it exists
			for child in slot_container.get_children():
				if child is Label:
					child.hide()

			# Check if sprite already exists for this slot
			var has_sprite = false
			for child in slot_container.get_children():
				if child is AnimatedSprite2D:
					has_sprite = true
					break

			# Add sprite if it doesn't exist
			if not has_sprite:
				_add_creature_sprite(assigned_creatures[i], i)
		else:
			# Show empty label
			for child in slot_container.get_children():
				if child is Label:
					child.show()
					child.text = "[Empty]"
				elif child is AnimatedSprite2D:
					child.queue_free()

func _can_drop_data(_position: Vector2, data) -> bool:
	# Facility cards accept creatures
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("creature") and can_accept_creature(data.creature)

func _drop_data(_position: Vector2, data) -> void:
	# Called when creature is dropped
	if data.has("creature") and data.has("source_node"):
		assign_creature(data.creature, data.source_node)

# Visual feedback during drag hover
func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		# Something is being dragged (might not be over us yet)
		pass
	elif what == NOTIFICATION_DRAG_END:
		# Drag operation ended
		modulate = Color.WHITE if not is_hover else Color(1.1, 1.1, 1.1)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right-click to start dragging the facility card itself
			accept_event()

func _get_drag_data(_position: Vector2):
	# Only allow dragging from the top panel/title area
	if _position.y > 50:  # Adjust this value based on your title bar height
		return null  # Don't start drag if clicking below title area
	# Only allow dragging if not fixed in place
	if current_slot == null:
		return null

	# Create preview
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(150, 100)
	var label = Label.new()
	label.text = facility_resource.facility_name if facility_resource else "Facility"
	preview.add_child(label)
	set_drag_preview(preview)

	return {
		"facility_card": self
	}

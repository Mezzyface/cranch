extends CanvasLayer
class_name FacilityDetailModal

# The facility view that opened this modal
var facility_view: Node = null

# Available facility resources
var available_facilities: Array[FacilityResource] = []

@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var facility_dropdown = $PanelContainer/MarginContainer/VBoxContainer/FacilityDropdown
@onready var description_label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var creature_label = $PanelContainer/MarginContainer/VBoxContainer/CreatureLabel
@onready var save_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/CloseButton

func _ready():
	save_button.pressed.connect(_on_save_pressed)
	close_button.pressed.connect(_on_close_pressed)
	facility_dropdown.item_selected.connect(_on_facility_selected)

func setup(p_facility_view: Node, p_available_facilities: Array[FacilityResource]):
	facility_view = p_facility_view
	available_facilities = p_available_facilities

	# Populate dropdown with available facilities
	_populate_dropdown()

	# Update creature label
	_update_creature_label()

func _populate_dropdown():
	facility_dropdown.clear()

	var selected_index = 0
	for i in range(available_facilities.size()):
		var facility = available_facilities[i]
		facility_dropdown.add_item(facility.facility_name, i)

		# Select current facility if it matches
		if facility_view.facility_resource and facility == facility_view.facility_resource:
			selected_index = i

	if available_facilities.size() > 0:
		facility_dropdown.select(selected_index)
		_update_description(selected_index)

func _update_description(index: int):
	if index >= 0 and index < available_facilities.size():
		var facility = available_facilities[index]
		var desc = facility.description + "\n\n"
		desc += "Activities:\n"
		for activity in facility.activities:
			desc += "  • %s: %s\n" % [activity.activity_name, activity.description]
		description_label.text = desc

func _update_creature_label():
	if facility_view.assigned_creature:
		creature_label.text = "Assigned Creature: %s" % facility_view.assigned_creature.creature_name
	else:
		creature_label.text = "Assigned Creature: None"

func _on_facility_selected(index: int):
	_update_description(index)

func _on_save_pressed():
	var selected_index = facility_dropdown.get_selected_id()
	if selected_index >= 0 and selected_index < available_facilities.size():
		var new_facility = available_facilities[selected_index]

		# Only update if different
		if facility_view.facility_resource != new_facility:
			# Unregister old assignment if creature exists
			if facility_view.assigned_creature and facility_view.facility_resource:
				if GameManager.facility_manager:
					GameManager.facility_manager.unregister_assignment(
						facility_view.assigned_creature,
						facility_view.facility_resource
					)

			# Update facility resource
			facility_view.facility_resource = new_facility

			# Update background to match new facility
			if facility_view.has_method("_update_background"):
				facility_view._update_background()

			# Re-register with new facility if creature exists
			if facility_view.assigned_creature:
				if GameManager.facility_manager:
					GameManager.facility_manager.register_assignment(
						facility_view.assigned_creature,
						new_facility
					)

			print("Changed facility to: %s" % new_facility.facility_name)

	queue_free()

func _on_close_pressed():
	queue_free()

# Static helper to show the modal
static func show_modal(parent_node: Node, p_facility_view: Node, p_available_facilities: Array[FacilityResource]):
	# Close any existing modal
	var existing_modal = parent_node.get_node_or_null("FacilityDetailModal")
	if existing_modal:
		existing_modal.queue_free()

	var modal_scene = preload("res://scenes/windows/facility_detail_modal.tscn")
	var modal = modal_scene.instantiate()
	modal.name = "FacilityDetailModal"
	parent_node.add_child(modal)
	modal.setup(p_facility_view, p_available_facilities)

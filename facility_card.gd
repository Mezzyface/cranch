# scenes/ui/facility_card.gd
extends Panel
class_name FacilityCard

@export var facility_resource: FacilityResource

@onready var name_label: Label = $VBoxContainer/Panel/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var activities_list: RichTextLabel = $VBoxContainer/MarginContainer/VBoxContainer/ActivitiesList
@onready var creature_slots: HBoxContainer = $VBoxContainer/MarginContainer/VBoxContainer/CreatureSlots
@onready var drop_area: Control = $DropArea

var assigned_creatures: Array[CreatureData] = []
var is_hover: bool = false

func _ready():
	if facility_resource:
		setup_facility(facility_resource)

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
		var slot = Label.new()
		slot.text = "[Empty Slot]"
		slot.modulate = Color(0.5, 0.5, 0.5)
		creature_slots.add_child(slot)

func _on_mouse_entered():
	is_hover = true
	modulate = Color(1.1, 1.1, 1.1)  # Slight highlight on hover

func _on_mouse_exited():
	is_hover = false
	modulate = Color.WHITE

func can_accept_creature(creature: CreatureData) -> bool:
	return assigned_creatures.size() < facility_resource.max_creatures

func assign_creature(creature: CreatureData, source_node: Node = null):
	if can_accept_creature(creature):
		assigned_creatures.append(creature)
		update_slots()

		# Run activities on the creature
		facility_resource.run_all_activities(creature)

		# Remove the source creature from the world
		if source_node:
			source_node.queue_free()

		# Emit signal
		SignalBus.facility_assigned.emit(creature, facility_resource)
		return true
	return false

func update_slots():
	for i in range(creature_slots.get_child_count()):
		var slot = creature_slots.get_child(i)
		if i < assigned_creatures.size():
			slot.text = assigned_creatures[i].creature_name
			slot.modulate = Color.WHITE
		else:
			slot.text = "[Empty Slot]"
			slot.modulate = Color(0.5, 0.5, 0.5)

func _can_drop_data(_position: Vector2, data) -> bool:
	# Called by Godot's drag and drop system to check if we can accept the drop
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

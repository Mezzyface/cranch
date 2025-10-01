# scripts/components/drag_drop_component.gd
extends Control
class_name DragDropComponent

## Unified drag and drop component that can be attached to any node
## Handles both dragging and dropping with configurable data types

enum DragType {
	CREATURE,           # Dragging a creature
	FACILITY_CARD,      # Dragging a facility card
	CUSTOM              # Custom drag data
}

## What type of data this component drags
@export var drag_type: DragType = DragType.CREATURE

## Whether this component can accept drops
@export var can_accept_drops: bool = false

## Whether this component can be dragged (set to false for drop-only zones)
@export var can_drag: bool = true

## Custom drop validation callback (if set, overrides default validation)
var custom_can_drop_callback: Callable

## Whether to hide the source node when dragging
@export var hide_on_drag: bool = true

## Alpha for the drag preview (0.0 - 1.0)
@export var preview_alpha: float = 0.7

## Enable debug visualization (shows colored overlay)
@export var debug_visualize: bool = false

## Mouse filter mode (set before adding to tree or use default PASS)
@export var mouse_filter_mode: MouseFilter = MOUSE_FILTER_PASS

# Internal references - set these programmatically
var drag_data_source: Node  # The node providing the drag data
var custom_drag_data: Dictionary = {}  # For CUSTOM type

# Click detection
var _mouse_pressed: bool = false
var _mouse_press_position: Vector2 = Vector2.ZERO
var _drag_threshold: float = 10.0  # Pixels of movement to trigger drag vs click

# Signals
signal drag_started(data: Dictionary)
signal drag_ended(successful: bool)
signal drop_received(data: Dictionary)
signal clicked()

func _ready():
	# Set mouse filter from exported property
	mouse_filter = mouse_filter_mode

	# Debug visualization
	if debug_visualize:
		draw.connect(_draw_debug)
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not can_drag:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_pressed = true
			_mouse_press_position = event.position
		else:
			# Mouse released
			if _mouse_pressed:
				var moved_distance = event.position.distance_to(_mouse_press_position)
				if moved_distance < _drag_threshold:
					# It's a click, not a drag
					clicked.emit()
			_mouse_pressed = false

func _draw_debug():
	# Draw a semi-transparent overlay to see the drag area
	var color = Color(1, 0, 0, 0.2) if drag_type == DragType.CREATURE else Color(0, 0, 1, 0.2)
	draw_rect(Rect2(Vector2.ZERO, size), color)

func _get_drag_data(_position: Vector2):
	# If this component can't be dragged, don't handle drag starts
	if not can_drag:
		return null

	var data = _build_drag_data()
	if data.is_empty():
		return null

	# Create preview
	var preview = _create_drag_preview()
	if preview:
		set_drag_preview(preview)

	# Hide source if configured
	if hide_on_drag and drag_data_source:
		drag_data_source.visible = false

	drag_started.emit(data)
	return data

func _build_drag_data() -> Dictionary:
	match drag_type:
		DragType.CREATURE:
			return _build_creature_drag_data()
		DragType.FACILITY_CARD:
			return _build_facility_card_drag_data()
		DragType.CUSTOM:
			return custom_drag_data
	return {}

func _build_creature_drag_data() -> Dictionary:
	# If custom_drag_data is set with creature info, use it
	if not custom_drag_data.is_empty() and custom_drag_data.has("creature"):
		return {
			"type": "creature",
			"creature": custom_drag_data.creature,
			"source_node": custom_drag_data.get("sprite", drag_data_source),
			"facility_card": custom_drag_data.get("facility_card"),  # Pass through facility reference
			"component": self
		}

	# Otherwise, try to extract from drag_data_source
	if not drag_data_source:
		return {}

	var creature_data: CreatureData = null

	# Try to get creature data from different source types
	if drag_data_source is CreatureDisplay:
		creature_data = drag_data_source.creature_data
	elif drag_data_source.has("creature_data"):
		creature_data = drag_data_source.creature_data

	if not creature_data:
		return {}

	return {
		"type": "creature",
		"creature": creature_data,
		"source_node": drag_data_source,
		"component": self
	}

func _build_facility_card_drag_data() -> Dictionary:
	if not drag_data_source:
		return {}

	# Facility card should have facility_resource
	if drag_data_source is FacilityCard:
		return {
			"type": "facility_card",
			"facility_card": drag_data_source,
			"component": self
		}

	return {}

func _create_drag_preview() -> Control:
	match drag_type:
		DragType.CREATURE:
			return _create_creature_preview()
		DragType.FACILITY_CARD:
			return _create_facility_card_preview()
		DragType.CUSTOM:
			return _create_custom_preview()
	return null

func _create_creature_preview() -> Control:
	var preview = TextureRect.new()

	# Try to get sprite texture
	var sprite: AnimatedSprite2D = null
	if drag_data_source and drag_data_source.has_node("AnimatedSprite2D"):
		sprite = drag_data_source.get_node("AnimatedSprite2D")
	elif drag_data_source and drag_data_source is AnimatedSprite2D:
		sprite = drag_data_source

	if sprite and sprite.sprite_frames:
		var current_animation = sprite.animation if sprite.animation else "idle"
		var current_frame = sprite.frame
		preview.texture = sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
		preview.modulate.a = preview_alpha
		preview.custom_minimum_size = Vector2(64, 64)

	return preview

func _create_facility_card_preview() -> Control:
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(150, 100)
	preview.modulate.a = preview_alpha

	var label = Label.new()
	if drag_data_source and drag_data_source is FacilityCard:
		label.text = drag_data_source.facility_resource.facility_name
	else:
		label.text = "Facility"

	preview.add_child(label)
	return preview

func _create_custom_preview() -> Control:
	# Override this in derived classes or set via script
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(100, 100)
	preview.modulate.a = preview_alpha
	return preview

func _can_drop_data(_position: Vector2, data) -> bool:
	if not can_accept_drops:
		return false

	if typeof(data) != TYPE_DICTIONARY:
		return false

	# Use custom callback if provided
	if custom_can_drop_callback.is_valid():
		return custom_can_drop_callback.call(data)

	# Check if we can accept this type of data
	var can_drop = false
	match drag_type:
		DragType.CREATURE:
			# If this is a creature drop zone, accept creatures
			can_drop = data.has("creature")
		DragType.FACILITY_CARD:
			# If this is a facility card drop zone, accept facility cards
			can_drop = data.has("facility_card")
		DragType.CUSTOM:
			# Custom validation - override this
			can_drop = _custom_can_drop(data)

	return can_drop

func _custom_can_drop(_data: Dictionary) -> bool:
	# Override this for custom drop validation
	return true

func _drop_data(_position: Vector2, data) -> void:
	drop_received.emit(data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Restore visibility if it was hidden
		if hide_on_drag and drag_data_source and is_instance_valid(drag_data_source):
			if not drag_data_source.is_queued_for_deletion():
				drag_data_source.visible = true

		drag_ended.emit(false)  # Assume unsuccessful unless overridden

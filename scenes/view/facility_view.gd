extends Control

# Facility configuration
@export var facility_resource: FacilityResource
@export var is_locked: bool = false
@export var unlock_cost: int = 100

# State
var assigned_creature: CreatureData = null
var assigned_food_id: String = ""
var creature_sprite: AnimatedSprite2D = null
var _was_swap: bool = false  # Track if last drag was a swap

@onready var panel_container = $PanelContainer
@onready var food_button = $FoodContainer/MarginContainer/FoodButton
@onready var lockscreen = $Lockscreen
@onready var drop_zone = $DropZone

func _ready():
	# Setup initial state
	if is_locked:
		_show_locked_state()
	else:
		_show_unlocked_state()

	# Connect signals
	food_button.pressed.connect(_on_food_button_pressed)

	# Setup drop zone
	if drop_zone:
		drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
			return data.has("creature") and not is_locked

		drop_zone.drop_received.connect(_on_creature_dropped)
		drop_zone.z_index = 10  # Put above panel contents so it can receive drag events

	# Make panel clickable for detail modal
	var click_detector = Button.new()
	click_detector.flat = true
	click_detector.custom_minimum_size = Vector2(128, 128)
	click_detector.mouse_filter = Control.MOUSE_FILTER_PASS
	click_detector.z_index = -1  # Put behind everything else so it doesn't block drag
	click_detector.pressed.connect(_on_facility_clicked)
	panel_container.add_child(click_detector)

func _show_locked_state():
	lockscreen.visible = true
	lockscreen.get_node("Label").text = "Locked\n%dg" % unlock_cost

func _show_unlocked_state():
	lockscreen.visible = false

func _on_creature_dropped(data: Dictionary):
	if not data.has("creature"):
		return

	var creature = data.get("creature") as CreatureData
	var source_node = data.get("source_node")
	var source_facility = data.get("source_facility")

	# If this facility already has a creature
	if assigned_creature:
		var old_creature = assigned_creature

		if source_facility:
			# Swap: both facilities exchange creatures
			assign_creature(creature)
			source_facility.assign_creature(old_creature)
			# Mark the source facility's drag as a swap (not a removal)
			source_facility._was_swap = true
		else:
			# From world: spawn old creature back to center
			assign_creature(creature)
			_spawn_creature_to_center(old_creature)

			# Remove the world Tino
			if source_node and is_instance_valid(source_node):
				source_node.queue_free()
	else:
		# No creature in this facility, just assign
		assign_creature(creature)

		# Remove the creature from the world (only if it's a Tino, not from facility)
		if source_node and is_instance_valid(source_node):
			if not source_facility:
				source_node.queue_free()

func _spawn_creature_to_center(creature: CreatureData):
	# Get the game scene to spawn the creature
	var game_scene = get_tree().current_scene
	if game_scene and game_scene.has_method("spawn_tino_at_position"):
		# Spawn at a random position on the platform
		var random_x = randf_range(500, 1420)
		game_scene.spawn_tino_at_position(creature, Vector2(random_x, 400))

func assign_creature(creature: CreatureData):
	# Remove old sprite if exists
	if creature_sprite:
		creature_sprite.queue_free()
		creature_sprite = null

	assigned_creature = creature

	# Get sprite frames for this creature
	var sprite_frames = GlobalEnums.get_sprite_frames_for_species(creature.species)

	if sprite_frames:
		# Create creature sprite
		creature_sprite = AnimatedSprite2D.new()
		creature_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		creature_sprite.position = Vector2(64, 64)  # Center of 128x128 panel
		creature_sprite.sprite_frames = sprite_frames
		creature_sprite.play("idle")

		panel_container.add_child(creature_sprite)
		creature_sprite.move_to_front()
	else:
		# Sprite frames not found - show placeholder text
		var placeholder = Label.new()
		placeholder.text = creature.creature_name[0] if creature.creature_name.length() > 0 else "?"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.custom_minimum_size = Vector2(128, 128)
		placeholder.add_theme_font_size_override("font_size", 48)

		panel_container.add_child(placeholder)

	# Setup drag component for dragging creature out of facility
	_setup_drag_component()

func _setup_drag_component():
	if not assigned_creature or not drop_zone:
		return

	# Disconnect old signals first to prevent duplicates
	if drop_zone.drag_started.is_connected(_on_drag_started):
		drop_zone.drag_started.disconnect(_on_drag_started)
	if drop_zone.drag_ended.is_connected(_on_drag_ended):
		drop_zone.drag_ended.disconnect(_on_drag_ended)

	# Enable dragging on the existing drop_zone
	drop_zone.can_drag = true
	drop_zone.drag_type = DragDropComponent.DragType.CREATURE  # Change from FACILITY_CARD to CREATURE
	drop_zone.hide_on_drag = false

	# Set drag_data_source to the sprite so preview works
	drop_zone.drag_data_source = creature_sprite

	# Use custom_drag_data to provide creature and facility info
	drop_zone.custom_drag_data = {
		"creature": assigned_creature,
		"sprite": creature_sprite,
		"source_facility": self
	}

	# IMPORTANT: Change mouse filter to STOP so it can receive drag input
	drop_zone.mouse_filter = Control.MOUSE_FILTER_STOP

	# Connect drag signals
	drop_zone.drag_started.connect(_on_drag_started)
	drop_zone.drag_ended.connect(_on_drag_ended)

func _on_drag_started(_data):
	# Make sprite semi-transparent during drag
	if creature_sprite:
		creature_sprite.modulate.a = 0.5

func _on_drag_ended(successful: bool):
	if successful:
		# If this was a swap, don't clear (the swap already assigned the new creature)
		if _was_swap:
			_was_swap = false  # Reset flag
		else:
			# Clear creature from this facility (dragged to center or empty facility)
			clear_creature()
	else:
		# Restore opacity if drag failed
		if creature_sprite:
			creature_sprite.modulate.a = 1.0

func clear_creature():
	"""Remove creature from facility slot"""
	if creature_sprite:
		creature_sprite.queue_free()
		creature_sprite = null

	assigned_creature = null

	# Reset drop zone to accept drops again
	if drop_zone:
		# Disconnect drag signals to prevent ghost events
		if drop_zone.drag_started.is_connected(_on_drag_started):
			drop_zone.drag_started.disconnect(_on_drag_started)
		if drop_zone.drag_ended.is_connected(_on_drag_ended):
			drop_zone.drag_ended.disconnect(_on_drag_ended)

		drop_zone.can_drag = false
		drop_zone.can_accept_drops = true  # Re-enable accepting drops
		drop_zone.drag_type = DragDropComponent.DragType.CREATURE  # Keep accepting creatures
		drop_zone.drag_data_source = null
		drop_zone.custom_drag_data = {}  # Clear drag data
		# Keep mouse_filter as IGNORE - drop detection works through _can_drop_data()
		# The initial drop zone setup already has the right mouse_filter

func _on_food_button_pressed():
	if not assigned_creature:
		print("No creature assigned - cannot select food")
		return

	# Open food selector for this creature
	SignalBus.food_selection_requested.emit(assigned_creature)

func _on_facility_clicked():
	if is_locked:
		print("Facility is locked - unlock for %dg" % unlock_cost)
		# TODO: Show unlock confirmation
		return

	# Show facility details modal
	_show_facility_modal()

func _show_facility_modal():
	print("Show facility modal - TODO")
	# TODO: Create modal showing:
	# - Facility name and description
	# - Stats/bonuses it provides
	# - Assigned creature (if any)
	# - Assigned food (if any)
	# - Activities available

func set_food(item_id: String):
	assigned_food_id = item_id
	# TODO: Update food icon visual
	print("Food set to: %s" % item_id)

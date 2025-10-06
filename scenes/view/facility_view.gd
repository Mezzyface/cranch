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
@onready var background_texture = $PanelContainer/Locationbackground
@onready var food_container = $FoodContainer
@onready var food_button = $FoodContainer/MarginContainer/FoodButton
@onready var lockscreen = $Lockscreen
@onready var drop_zone = $DropZone
@onready var creature_name_label = $CreatureName

func _ready():
	# Setup initial state
	if is_locked:
		_show_locked_state()
	else:
		_show_unlocked_state()

	# Update background based on facility resource
	_update_background()

	# Hide food container initially (shown when creature assigned)
	if food_container:
		food_container.hide()

	# Hide creature name label initially (shown when creature assigned)
	if creature_name_label:
		creature_name_label.hide()

	# Connect signals
	food_button.pressed.connect(_on_food_button_pressed)
	SignalBus.creature_food_assigned.connect(_on_food_assigned)
	SignalBus.creature_food_unassigned.connect(_on_food_unassigned)
	SignalBus.creature_removed.connect(_on_creature_removed)

	# Setup drop zone
	if drop_zone:
		drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
			return data.has("creature") and not is_locked

		drop_zone.drop_received.connect(_on_creature_dropped)
		drop_zone.clicked.connect(_on_facility_clicked)
		drop_zone.z_index = 10  # Put above panel contents so it can receive drag events

func _show_locked_state():
	lockscreen.visible = true
	lockscreen.get_node("Label").text = "Locked\n%dg" % unlock_cost

func _show_unlocked_state():
	lockscreen.visible = false

func _update_background():
	"""Update the background texture based on facility_resource"""
	if not facility_resource or not background_texture:
		return

	if not facility_resource.background_path.is_empty():
		var texture = load(facility_resource.background_path)
		if texture:
			background_texture.texture = texture

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

	# Update creature name label
	if creature_name_label:
		creature_name_label.text = creature.creature_name
		creature_name_label.show()

	# Register with FacilityManager if we have a facility resource
	if facility_resource and GameManager.facility_manager:
		GameManager.facility_manager.register_assignment(creature, facility_resource)

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

	# Show food container now that creature is assigned
	if food_container:
		food_container.show()

	# Check if creature already has food assigned and update button
	var existing_food = GameManager.facility_manager.get_assigned_food(creature)
	if not existing_food.is_empty():
		assigned_food_id = existing_food
	else:
		assigned_food_id = ""
	_update_food_button_texture()

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
	# Unregister from FacilityManager before clearing
	if assigned_creature and facility_resource and GameManager.facility_manager:
		GameManager.facility_manager.unregister_assignment(assigned_creature, facility_resource)

	if creature_sprite:
		creature_sprite.queue_free()
		creature_sprite = null

	assigned_creature = null

	# Clear creature name label
	if creature_name_label:
		creature_name_label.text = ""
		creature_name_label.hide()

	# Hide food container when no creature assigned
	if food_container:
		food_container.hide()

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
		_show_unlock_confirmation()
		return

	# Show facility details modal
	_show_facility_modal()

func _show_unlock_confirmation():
	"""Show confirmation dialog to unlock this facility"""
	var message = "Unlock this facility for %dg?" % unlock_cost
	var modal_scene = preload("res://scenes/windows/generic_message_modal.tscn")
	var modal = modal_scene.instantiate()
	modal.title = "Unlock Facility"
	modal.message = message

	# Override the close button to be "Yes/No" buttons
	var game_scene = get_tree().current_scene
	if game_scene:
		game_scene.add_child(modal)

		# Replace single button with Yes/No
		var button_container = modal.get_node("PanelContainer/MarginContainer/VBoxContainer/CloseButton").get_parent()
		var close_button = modal.get_node("PanelContainer/MarginContainer/VBoxContainer/CloseButton")
		close_button.queue_free()

		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var yes_button = Button.new()
		yes_button.text = "Yes (%dg)" % unlock_cost
		yes_button.custom_minimum_size = Vector2(120, 40)
		yes_button.pressed.connect(func():
			_attempt_unlock()
			modal.queue_free()
		)

		var no_button = Button.new()
		no_button.text = "No"
		no_button.custom_minimum_size = Vector2(120, 40)
		no_button.pressed.connect(func(): modal.queue_free())

		hbox.add_child(yes_button)
		hbox.add_child(no_button)
		button_container.add_child(hbox)

func _attempt_unlock():
	"""Try to unlock the facility by spending gold"""
	# Check if player has enough gold
	if GameManager.player_data.gold < unlock_cost:
		var modal_scene = preload("res://scenes/windows/generic_message_modal.tscn")
		var modal = modal_scene.instantiate()
		modal.title = "Not Enough Gold"
		modal.message = "You need %dg to unlock this facility.\nYou only have %dg." % [unlock_cost, GameManager.player_data.gold]
		get_tree().current_scene.add_child(modal)
		return

	# Deduct gold
	SignalBus.gold_change_requested.emit(-unlock_cost)

	# Unlock facility
	is_locked = false
	_show_unlocked_state()

	print("Facility unlocked for %dg" % unlock_cost)

func _show_facility_modal():
	# Load all available facilities
	var available_facilities: Array[FacilityResource] = []

	var facilities_dir = "res://resources/facilities/"
	var dir = DirAccess.open(facilities_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var facility_path = facilities_dir + file_name
				var facility = load(facility_path) as FacilityResource
				if facility:
					available_facilities.append(facility)
			file_name = dir.get_next()

		dir.list_dir_end()

	# Show modal with available facilities
	var game_scene = get_tree().current_scene
	if game_scene:
		FacilityDetailModal.show_modal(game_scene, self, available_facilities)

func set_food(item_id: String):
	assigned_food_id = item_id
	_update_food_button_texture()
	print("Food set to: %s" % item_id)

func _update_food_button_texture():
	"""Update the food button texture based on assigned food"""
	if not food_button:
		return

	if assigned_food_id.is_empty():
		# No food assigned - show red X or empty indicator
		var empty_texture = load("res://assets/Red_X.svg.png")
		food_button.texture_normal = empty_texture
	else:
		# Food assigned - show food icon
		var food_item = GameManager.inventory_manager.get_item_resource(assigned_food_id)
		if food_item and not food_item.icon_path.is_empty():
			var food_texture = load(food_item.icon_path)
			food_button.texture_normal = food_texture
		else:
			# Fallback to empty texture if food resource not found
			var empty_texture = load("res://assets/Red_X.svg.png")
			food_button.texture_normal = empty_texture

func _on_food_assigned(creature: CreatureData, item_id: String):
	"""Called when food is assigned to any creature via SignalBus"""
	# Only update if this is our creature
	if creature == assigned_creature:
		assigned_food_id = item_id
		_update_food_button_texture()

func _on_food_unassigned(creature: CreatureData):
	"""Called when food is unassigned from any creature via SignalBus"""
	# Only update if this is our creature
	if creature == assigned_creature:
		assigned_food_id = ""
		_update_food_button_texture()

func _on_creature_removed(creature: CreatureData):
	"""Called when a creature is removed from the game (e.g., turned in for quest)"""
	# Only clear if this is our creature
	if creature == assigned_creature:
		clear_creature()

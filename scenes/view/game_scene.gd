extends Control

# Preload the debug popup scene
const DEBUG_POPUP = preload("res://scenes/windows/debug_popup.tscn")
const WEEK_DISPLAY = preload("res://scenes/card/week_display.tscn")
const CREATURE_DISPLAY = preload("res://scenes/entities/creature_display.tscn")
const CREATURE_STATS_POPUP:PackedScene = preload("res://scenes/windows/creature_stats_popup.tscn")

const FacilitySlot = preload("res://scenes/card/facility_slot.gd")
const STRENGTH_TRAINING = preload("res://resources/activities/strength_training.gd")


@onready var creature_container: PanelContainer = $CreatureContainer

func _ready():
	# Connect to know when data is ready
	_connect_signals()
	
	# Initialize the game when scene loads
	SignalBus.game_started.emit()
	
	_setup_container_drop_handling()
	_create_week_display()
	_create_facility_slots()

func _input(event):
	# Quick save with F5
	if event.is_action_pressed("ui_page_down"):  # F5 key
		SaveManager.save_game()
		_show_save_notification()

	# Quick load with F9
	elif event.is_action_pressed("ui_page_up"):  # F9 key
		if SaveManager.load_game():
			_refresh_display()
			_show_load_notification()

func _connect_signals():
	SignalBus.player_data_initialized.connect(_on_player_data_ready)
	SignalBus.creature_added.connect(_on_creature_added)
	SignalBus.creature_clicked.connect(_on_creature_clicked)

func _on_player_data_ready():
	# Show debug popup with player data
	show_debug_popup()

func _on_creature_added(creature: CreatureData):
	print("_on_creature_added")
	# Spawn individual creature when added
	_spawn_creature(creature)
	
func _spawn_player_creatures():
	print("_spawn_player_creatures")
	if not GameManager.player_data:
		return

	# Clear existing creatures
	for child in creature_container.get_children():
		if child is CreatureDisplay:
			child.queue_free()

	# Spawn each creature
	for creature in GameManager.player_data.creatures:
		_spawn_creature(creature)


func _spawn_creature(creature_data: CreatureData):
	var creature_instance = CREATURE_DISPLAY.instantiate()
	creature_container.add_child(creature_instance)

	# Set creature data
	creature_instance.set_creature_data(creature_data)

	# Get container bounds and pass to creature
	var container_size = creature_container.get_rect().size
	var container_bounds = Rect2(Vector2.ZERO, container_size)
	creature_instance.set_container_bounds(container_bounds)

	# Position randomly within container
	var padding = 20.0
	var random_pos = Vector2(
		randf_range(padding, container_size.x - padding),
		randf_range(padding, container_size.y - padding)
	)
	creature_instance.position = random_pos

	# Create drag component for this creature - layer 2 (on top of drop zone)
	_create_creature_drag_component(creature_instance, creature_data)

func _create_creature_drag_component(creature_instance: CreatureDisplay, creature_data: CreatureData):
	# Create drag component positioned over the creature
	var drag_component = DragDropComponent.new()
	drag_component.name = "CreatureDrag_" + creature_data.creature_name
	drag_component.drag_type = DragDropComponent.DragType.CREATURE
	drag_component.drag_data_source = creature_instance
	drag_component.mouse_filter_mode = Control.MOUSE_FILTER_STOP
	drag_component.z_index = 200  # Well above container elements

	# Size to cover the creature sprite (64x64 typical)
	drag_component.custom_minimum_size = Vector2(64, 64)
	drag_component.size = Vector2(64, 64)

	# Connect to creature for position updates
	drag_component.set_meta("creature_instance", creature_instance)

	# Connect signals
	drag_component.drag_started.connect(func(_data):
		if creature_instance and is_instance_valid(creature_instance):
			creature_instance.visible = false
	)

	drag_component.drag_ended.connect(func(_successful):
		if creature_instance and is_instance_valid(creature_instance):
			creature_instance.visible = true
	)

	drag_component.clicked.connect(func():
		if creature_instance and is_instance_valid(creature_instance) and creature_instance.creature_data:
			SignalBus.creature_clicked.emit(creature_instance.creature_data)
	)

	# Add as sibling to container (not child) to avoid mouse filter conflicts
	add_child(drag_component)

	# Position it over the creature (will be updated each frame)
	_update_creature_drag_position(drag_component, creature_instance)

func _update_creature_drag_position(drag_component: DragDropComponent, creature_instance: CreatureDisplay):
	if creature_instance and is_instance_valid(creature_instance):
		# Position drag component using global coordinates (since it's a sibling, not child)
		var creature_global_pos = creature_instance.global_position
		drag_component.global_position = creature_global_pos - Vector2(32, 32)

func _process(_delta):
	# Update all creature drag component positions and clean up orphans
	for child in get_children():
		if child is DragDropComponent and child.name.begins_with("CreatureDrag_"):
			var creature_instance = child.get_meta("creature_instance", null)
			if creature_instance and is_instance_valid(creature_instance):
				_update_creature_drag_position(child, creature_instance)
			else:
				# Creature was freed, remove this drag component
				child.queue_free()

func show_debug_popup():
	# Create and display the debug popup
	print("Show Debug Popup")
	var popup = DEBUG_POPUP.instantiate()
	add_child(popup)

	# Pass the data to the popup
	if popup.has_method("set_player_data"):
		popup.set_player_data(GameManager.player_data)

	# Center the popup on screen
	popup.popup_centered()

func _show_save_notification():
	# Simple notification (you can make this fancier)
	print("Game saved!")
	# Could add a popup or UI notification here

func _show_load_notification():
	print("Game loaded!")
	# Could add a popup or UI notification here

func _refresh_display():
	# Clear creatures from container
	for child in creature_container.get_children():
		if child is CreatureDisplay:
			child.queue_free()

	# Clear creature drag components from game scene
	for child in get_children():
		if child is DragDropComponent and child.name.begins_with("CreatureDrag_"):
			child.queue_free()

	# Respawn creatures from loaded data
	for creature in GameManager.player_data.creatures:
		_spawn_creature(creature)

func _setup_container_drop_handling():
	if creature_container:
		# Create drop zone component for the container - layer 1 (base drop layer)
		var drop_zone = DragDropComponent.new()
		drop_zone.name = "ContainerDropZone"
		drop_zone.drag_type = DragDropComponent.DragType.CREATURE
		drop_zone.can_accept_drops = true
		drop_zone.can_drag = false  # Drop-only zone
		drop_zone.mouse_filter_mode = Control.MOUSE_FILTER_STOP
		drop_zone.z_index = 100

		# Fill the entire container
		drop_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
		drop_zone.set_offsets_preset(Control.PRESET_FULL_RECT)

		# Custom validation
		drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
			return data.has("creature")

		# Connect drop signal
		drop_zone.drop_received.connect(_on_container_drop_received)

		# Add to container
		creature_container.add_child(drop_zone)

		print("Container drop handling enabled")

func _on_container_drop_received(data: Dictionary):
	if not data.has("creature"):
		return

	var creature_data = data.get("creature")
	var source_node = data.get("source_node")

	# Check if dropping from world (source is CreatureDisplay) or facility (source is sprite)
	if source_node and is_instance_valid(source_node) and source_node is CreatureDisplay:
		# Dropping from world - just reposition
		source_node.visible = true

		# Get global mouse position (where the drop occurred)
		var drop_pos = creature_container.get_global_mouse_position()

		# Convert global position to container local position
		var local_pos = creature_container.get_global_transform().affine_inverse() * drop_pos

		# Apply position with padding constraints
		var padding = 20.0
		var container_size = creature_container.get_rect().size
		source_node.position = Vector2(
			clamp(local_pos.x, padding, container_size.x - padding),
			clamp(local_pos.y, padding, container_size.y - padding)
		)
	else:
		# Dropping from facility - spawn new CreatureDisplay
		# Get global mouse position
		var drop_pos = creature_container.get_global_mouse_position()
		_spawn_creature_at_position(creature_data, drop_pos)

		# Remove from facility if applicable
		var facility_card = data.get("facility_card")
		if facility_card and facility_card is FacilityCard:
			# Remove the sprite from the facility
			if source_node and is_instance_valid(source_node) and source_node is AnimatedSprite2D:
				facility_card.remove_creature_by_sprite(source_node)

func _spawn_creature_at_position(creature_data: CreatureData, global_pos: Vector2):
	var creature_instance = CREATURE_DISPLAY.instantiate()
	creature_container.add_child(creature_instance)

	# Set creature data
	creature_instance.set_creature_data(creature_data)

	# Get container bounds and pass to creature
	var container_size = creature_container.get_rect().size
	var container_bounds = Rect2(Vector2.ZERO, container_size)
	creature_instance.set_container_bounds(container_bounds)

	# Convert global position to container local position
	var local_pos = creature_container.get_global_transform().affine_inverse() * global_pos

	# Apply position with padding constraints
	var padding = 20.0
	creature_instance.position = Vector2(
		clamp(local_pos.x, padding, container_size.x - padding),
		clamp(local_pos.y, padding, container_size.y - padding)
	)

	# Create drag component for this creature
	_create_creature_drag_component(creature_instance, creature_data)

func _create_week_display():
	var week_display = WEEK_DISPLAY.instantiate()
	add_child(week_display)
#
func _create_facility_slots():
	# Slots now exist in the scene tree as direct children
	# Just connect their signals
	for child in get_children():
		if child is FacilitySlot:
			# Connect signals
			child.facility_placed.connect(_on_facility_placed)
			child.facility_removed.connect(_on_facility_removed)

	# Place test facility in first slot
	_place_test_facility_in_slot()

func _place_test_facility_in_slot():
	# Get first slot from scene tree
	var first_slot = $FacilitySlot1
	if first_slot:

		# Create test facility card
		var training_facility = FacilityResource.new()
		training_facility.facility_name = "Training Grounds"
		training_facility.description = "Train your creatures"
		training_facility.max_creatures = 2

		# Add a strength training activity
		var strength_activity = STRENGTH_TRAINING.new()
		strength_activity.strength_gain = 5 
		training_facility.activities.append(strength_activity)

		# Create and place card
		var card_scene = preload("res://scenes/card/facility_card.tscn")
		var card = card_scene.instantiate()
		card.facility_resource = training_facility
		card.add_to_group("facility_cards")

		first_slot.place_facility(card)

func _on_facility_placed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility placed: ", facility_card.facility_resource.facility_name, " in slot ", slot.slot_index)

func _on_facility_removed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility removed from slot ", slot.slot_index)

func _on_creature_clicked(creature_data: CreatureData) -> void:
	# Create and show popup
	var popup = CREATURE_STATS_POPUP.instantiate()
	add_child(popup)
	popup.setup(creature_data)
	

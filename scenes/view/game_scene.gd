extends Control

# Preload the debug popup scene
const DEBUG_POPUP = preload("res://scenes/windows/debug_popup.tscn")
const WEEK_DISPLAY = preload("res://scenes/card/week_display.tscn")
const CREATURE_DISPLAY = preload("res://scenes/entities/creature_display.tscn")
const CREATURE_STATS_POPUP:PackedScene = preload("res://scenes/windows/creature_stats_popup.tscn")
const SHOP_WINDOW = preload("res://scenes/windows/shop_window.tscn")
const QUEST_WINDOW = preload("res://scenes/windows/quest_window.tscn")
const QUEST_CREATURE_SELECTOR = preload("res://scenes/windows/quest_creature_selector.tscn")
const TINO_CREATURE = preload("res://scenes/entities/tino_creature.tscn")
const GENERIC_MESSAGE_MODAL = preload("res://scenes/windows/generic_message_modal.tscn")

const FacilitySlot = preload("res://scenes/card/facility_slot.gd")
const STRENGTH_TRAINING = preload("res://resources/activities/strength_training.gd")

# Preload facility resources
const STRENGTH_FACILITY = preload("res://resources/facilities/strength_training.tres")
const AGILITY_FACILITY = preload("res://resources/facilities/agility_training.tres")
const INTELLIGENCE_FACILITY = preload("res://resources/facilities/intelligence_training.tres")

# @onready var creature_container: PanelContainer = $UILayer/CreatureContainer  # Removed for tileset rework
@onready var next_week_button: Button = $UILayer/WeekBox/MarginContainer/NextWeekButton

func _ready():
	# Connect to know when data is ready
	_connect_signals()

	# Initialize simulation
	if has_node("/root/SimulationManager"):
		get_node("/root/SimulationManager").start_simulation()

	# Connect Next Week button
	if next_week_button:
		next_week_button.pressed.connect(_on_next_week_pressed)

	# Initialize the game when scene loads
	SignalBus.game_started.emit()

	# _setup_container_drop_handling()  # Commented out - creature container removed
	_create_week_display()
	# _create_facility_slots()  # Disabled - using scene-based slots instead
	_setup_center_drop_zone()

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

	# Open Store Selector with F6
	elif event.is_action_pressed("ui_text_backspace"):  # F6 key
		StoreSelectorHelper.open_store_selector(self)

	# Open Quest Log with Q key
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			open_quest_window()

func _connect_signals():
	SignalBus.player_data_initialized.connect(_on_player_data_ready)
	SignalBus.creature_added.connect(_on_creature_added)
	SignalBus.creature_removed.connect(_on_creature_removed)
	SignalBus.creature_clicked.connect(_on_creature_clicked)
	SignalBus.quest_turn_in_started.connect(_on_quest_turn_in_started)
	SignalBus.food_selection_requested.connect(_on_food_selection_requested)
	SignalBus.week_advancement_blocked.connect(_on_week_advancement_blocked)
	SignalBus.gold_changed.connect(_on_gold_changed)
	SignalBus.week_advanced.connect(_on_week_advanced)
	SignalBus.competition_completed.connect(_on_competition_completed)
	SignalBus.creature_died.connect(_on_creature_died)

func _on_player_data_ready():
	# Debug popup disabled for now
	# show_debug_popup()
	pass

func _on_creature_added(creature: CreatureData):
	# 1. Create simulation entity
	var sim_creature = SimCreature.new(creature)
	sim_creature.container_bounds = Rect2(585, 300, 750, 300)  # Define simulation bounds
	sim_creature.position = Vector2(randf_range(585, 1335), 400)
	var sim_id = get_node("/root/SimulationManager").register_creature(sim_creature)

	# 2. Create view entity
	var creature_view = CREATURE_DISPLAY.instantiate()  # Or CREATURE_VIEW if renamed
	creature_view.set_creature_data(creature)
	creature_view.set_sim_id(sim_id)
	add_child(creature_view)  # Or appropriate container

	# 3. Register view with ViewManager
	get_node("/root/ViewManager").creature_views[sim_id] = creature_view

func _on_creature_removed(creature: CreatureData):
	print("_on_creature_removed: ", creature.creature_name)
	# Disabled for tileset rework
	pass
	# # Find and remove the CreatureDisplay node for this creature
	# for child in creature_container.get_children():
	# 	if child is CreatureDisplay and child.creature_data == creature:
	# 		print("Removing CreatureDisplay for: ", creature.creature_name)
	# 		child.queue_free()
	# 		break

	# # Clean up the associated drag component
	# for child in get_children():
	# 	if child is DragDropComponent and child.name == "CreatureDrag_" + creature.creature_name:
	# 		print("Removing drag component for: ", creature.creature_name)
	# 		child.queue_free()
	# 		break
	
func _spawn_player_creatures():
	print("_spawn_player_creatures - disabled for tileset rework")
	return  # Disabled for tileset rework
	# if not GameManager.player_data:
	# 	return

	# # Clear existing creatures
	# for child in creature_container.get_children():
	# 	if child is CreatureDisplay:
	# 		child.queue_free()

	# # Spawn each creature
	# for creature in GameManager.player_data.creatures:
	# 	_spawn_creature(creature)


func _spawn_creature(creature_data: CreatureData):
	print("_spawn_creature - disabled for tileset rework")
	return  # Disabled for tileset rework
	# var creature_instance = CREATURE_DISPLAY.instantiate()
	# creature_container.add_child(creature_instance)

	# # Set creature data
	# creature_instance.set_creature_data(creature_data)

	# # Get container bounds and pass to creature
	# var container_size = creature_container.get_rect().size
	# var container_bounds = Rect2(Vector2.ZERO, container_size)
	# creature_instance.set_container_bounds(container_bounds)

	# # Position randomly within container
	# var padding = 20.0
	# var random_pos = Vector2(
	# 	randf_range(padding, container_size.x - padding),
	# 	randf_range(padding, container_size.y - padding)
	# )
	# creature_instance.position = random_pos

	# # Create drag component for this creature - layer 2 (on top of drop zone)
	# _create_creature_drag_component(creature_instance, creature_data)

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
	print("_refresh_display - disabled for tileset rework")
	return  # Disabled for tileset rework
	# # Clear creatures from container
	# for child in creature_container.get_children():
	# 	if child is CreatureDisplay:
	# 		child.queue_free()

	# # Clear creature drag components from game scene
	# for child in get_children():
	# 	if child is DragDropComponent and child.name.begins_with("CreatureDrag_"):
	# 		child.queue_free()

	# # Respawn creatures from loaded data
	# for creature in GameManager.player_data.creatures:
	# 	_spawn_creature(creature)

func _setup_container_drop_handling():
	print("_setup_container_drop_handling - disabled for tileset rework")
	return  # Disabled for tileset rework

func _on_container_drop_received(data: Dictionary):
	print("_on_container_drop_received - disabled for tileset rework")
	return  # Disabled for tileset rework

func _spawn_creature_at_position(creature_data: CreatureData, global_pos: Vector2):
	print("_spawn_creature_at_position - disabled for tileset rework")
	return  # Disabled for tileset rework

func _create_week_display():
	var week_display = WEEK_DISPLAY.instantiate()
	add_child(week_display)
#
func _create_facility_slots():
	# Create 5 facility slots positioned over the blue boxes on the tilemap
	var slot_scene = preload("res://scenes/card/facility_slot.tscn")

	# Based on image: 5 boxes at bottom with blue indicators below
	# Approximate positions for slots (adjust based on actual tile positions)
	var slot_positions = [
		Vector2(150, 850),   # Slot 1 - left
		Vector2(550, 850),   # Slot 2
		Vector2(950, 850),   # Slot 3 - center
		Vector2(1350, 850),  # Slot 4
		Vector2(1750, 850)   # Slot 5 - right
	]

	for i in range(5):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.position = slot_positions[i]

		# Connect signals
		slot.facility_placed.connect(_on_facility_placed)
		slot.facility_removed.connect(_on_facility_removed)

		# Add to UILayer so it stays fixed with camera
		$UILayer.add_child(slot)

		print("Created facility slot %d at position %s" % [i, slot_positions[i]])

	# Slots created, ready for custom facilities
	# _place_test_facility_in_slot()  # Disabled - making new facilities

func _place_test_facility_in_slot():
	# Load training facilities into the new dynamically created slots
	var card_scene = preload("res://scenes/card/facility_card.tscn")

	# Get all facility slots from UILayer
	var slots = []
	for child in $UILayer.get_children():
		if child is FacilitySlot:
			slots.append(child)

	# Sort by slot_index to ensure correct order
	slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)

	# Slot 0: Strength Training
	if slots.size() > 0:
		var card1 = card_scene.instantiate()
		card1.facility_resource = STRENGTH_FACILITY
		card1.add_to_group("facility_cards")
		slots[0].place_facility(card1)

	# Slot 1: Agility Training
	if slots.size() > 1:
		var card2 = card_scene.instantiate()
		card2.facility_resource = AGILITY_FACILITY
		card2.add_to_group("facility_cards")
		slots[1].place_facility(card2)

	# Slot 2: Intelligence Training
	if slots.size() > 2:
		var card3 = card_scene.instantiate()
		card3.facility_resource = INTELLIGENCE_FACILITY
		card3.add_to_group("facility_cards")
		slots[2].place_facility(card3)

func _on_facility_placed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility placed: ", facility_card.facility_resource.facility_name, " in slot ", slot.slot_index)

func _on_facility_removed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility removed from slot ", slot.slot_index)

func _on_creature_clicked(creature_data: CreatureData) -> void:
	# Close any existing creature stats popup to prevent stacking
	_close_existing_creature_stats_popup()

	# Create and show popup
	var popup = CREATURE_STATS_POPUP.instantiate()
	popup.name = "CreatureStatsPopup"  # Give it a unique name
	add_child(popup)
	popup.setup(creature_data)

func _close_existing_creature_stats_popup():
	"""Close any existing creature stats popup"""
	var existing_popup = get_node_or_null("CreatureStatsPopup")
	if existing_popup:
		existing_popup.queue_free()

func open_quest_window():
	# Prevent multiple instances
	if get_node_or_null("QuestWindow"):
		return

	var quest_window = QUEST_WINDOW.instantiate()
	quest_window.name = "QuestWindow"
	add_child(quest_window)

	SignalBus.quest_log_opened.emit()

func _on_quest_turn_in_started(quest: QuestResource):
	# Prevent multiple instances
	if get_node_or_null("QuestCreatureSelector"):
		return

	var selector = QUEST_CREATURE_SELECTOR.instantiate()
	selector.name = "QuestCreatureSelector"
	add_child(selector)
	selector.setup(quest)

func _on_food_selection_requested(creature: CreatureData):
	FoodSelectorHelper.open_food_selector(self, creature)

func _on_week_advancement_blocked(reason: String, creatures: Array):
	print("⚠️ Cannot advance week: %s" % reason)

	# Build creature list message
	var creature_names: Array[String] = []
	for creature in creatures:
		if creature is CreatureData:
			creature_names.append(creature.creature_name)
			print("  - %s needs food" % creature.creature_name)

	# Show modal popup
	_show_week_blocked_modal(reason, creature_names)

func _show_week_blocked_modal(reason: String, creature_names: Array[String]):
	"""Show modal informing player which creatures need food"""
	# Build message with creature list
	var message = "The following creatures need food assigned:\n\n"
	for creature_name in creature_names:
		message += "• %s\n" % creature_name
	message += "\nAssign food to all creatures before advancing the week."

	# Show simple message modal
	var modal = GENERIC_MESSAGE_MODAL.instantiate()
	modal.title = "⚠️ Cannot Advance Week"
	modal.message = message
	add_child(modal)

func _on_gold_changed(gold_amount: int):
	var gold_label = get_node_or_null("UILayer/GoldBox/Gold")
	if gold_label:
		gold_label.text = str(gold_amount)

func _on_week_advanced(week_number: int):
	var week_label = get_node_or_null("UILayer/WeekBox/Label")
	if week_label:
		week_label.text = "Week %d" % week_number


func _setup_center_drop_zone():
	# Use the DragDropComponent you added to the scene
	var drop_zone = get_node_or_null("Dropzone/DragDropComponent")
	if not drop_zone:
		return

	# Configure the drop zone properties
	drop_zone.can_accept_drops = true
	drop_zone.can_drag = false
	drop_zone.drag_type = DragDropComponent.DragType.CREATURE
	drop_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	drop_zone.z_index = 100  # Make sure it's on top

	# Make it fill the parent Dropzone control
	drop_zone.anchors_preset = Control.PRESET_FULL_RECT
	drop_zone.anchor_left = 0
	drop_zone.anchor_top = 0
	drop_zone.anchor_right = 1
	drop_zone.anchor_bottom = 1
	drop_zone.offset_left = 0
	drop_zone.offset_top = 0
	drop_zone.offset_right = 0
	drop_zone.offset_bottom = 0

	# Set up drop validation
	drop_zone.custom_can_drop_callback = func(data: Dictionary) -> bool:
		return data.has("creature")

	# Handle creature drops
	drop_zone.drop_received.connect(_on_center_drop_received)

func _on_center_drop_received(data: Dictionary):
	if not data.has("creature"):
		return

	var creature = data.get("creature") as CreatureData
	var source_node = data.get("source_node")
	var source_facility = data.get("source_facility")

	# Get the drop position - convert from screen to world coordinates
	var camera = get_node_or_null("Camera2D")
	var screen_position = get_viewport().get_mouse_position()
	var world_position = screen_position

	if camera:
		# Account for camera offset and zoom
		var camera_offset = camera.position - get_viewport_rect().size / 2.0 / camera.zoom
		world_position = screen_position / camera.zoom + camera_offset

	# Clamp to platform bounds (X: 400-1520, Y: 400 for ground level)
	var clamped_x = clamp(world_position.x, 400, 1520)
	var position = Vector2(clamped_x, 400)

	# Check if creature is from the world or from a facility
	if source_node and is_instance_valid(source_node) and not source_facility:
		# Creature is from the world - just reposition it
		source_node.position = position
	else:
		# Creature is from a facility or new - spawn a new one
		spawn_tino_at_position(creature, position)

func spawn_tino_at_position(creature: CreatureData, position: Vector2):
	"""Helper method to spawn a Tino creature at a specific position"""
	var tino = TINO_CREATURE.instantiate()
	add_child(tino)

	tino.creature_data = creature
	tino.position = position

	# Set platform bounds
	var movement_controller = tino.get_node_or_null("WanderMovementController")
	if movement_controller:
		movement_controller.platform_bounds = Vector2(400, 1520)

func _on_next_week_pressed():
	"""Called when Next Week button is pressed"""
	GameManager.advance_week()

func _on_competition_completed(competition: CompetitionResource, results: Array):
	"""Called when a competition finishes - shows results popup"""
	var results_popup = preload("res://scenes/windows/competition_results_popup.tscn").instantiate()
	results_popup.setup(competition, results)
	add_child(results_popup)

func _on_creature_died(creature: CreatureData, cause: String):
	"""Called when a creature dies - handles cleanup and notifications"""
	print("%s died: %s" % [creature.creature_name, cause])
	# TODO: Add death animation, memorial popup, etc.

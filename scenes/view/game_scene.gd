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

const FacilitySlot = preload("res://scenes/card/facility_slot.gd")
const STRENGTH_TRAINING = preload("res://resources/activities/strength_training.gd")

# Preload facility resources
const STRENGTH_FACILITY = preload("res://resources/facilities/strength_training.tres")
const AGILITY_FACILITY = preload("res://resources/facilities/agility_training.tres")
const INTELLIGENCE_FACILITY = preload("res://resources/facilities/intelligence_training.tres")

# @onready var creature_container: PanelContainer = $UILayer/CreatureContainer  # Removed for tileset rework

func _ready():
	# Connect to know when data is ready
	_connect_signals()
	
	# Initialize the game when scene loads
	SignalBus.game_started.emit()
	
	# _setup_container_drop_handling()  # Commented out - creature container removed
	_create_week_display()
	_create_facility_slots()
	_spawn_tinos()

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

func _on_player_data_ready():
	# Debug popup disabled for now
	# show_debug_popup()
	pass

func _on_creature_added(creature: CreatureData):
	print("_on_creature_added")
	# Spawn individual creature when added
	# _spawn_creature(creature)  # Disabled for tileset rework
	pass

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
	# Load the three training facilities into slots
	var card_scene = preload("res://scenes/card/facility_card.tscn")

	# Slot 1: Strength Training
	var slot1 = $FacilitySlot1
	if slot1:
		var card1 = card_scene.instantiate()
		card1.facility_resource = STRENGTH_FACILITY
		card1.add_to_group("facility_cards")
		slot1.place_facility(card1)

	# Slot 2: Agility Training
	var slot2 = $FacilitySlot2
	if slot2:
		var card2 = card_scene.instantiate()
		card2.facility_resource = AGILITY_FACILITY
		card2.add_to_group("facility_cards")
		slot2.place_facility(card2)

	# Slot 3: Intelligence Training
	var slot3 = $FacilitySlot3
	if slot3:
		var card3 = card_scene.instantiate()
		card3.facility_resource = INTELLIGENCE_FACILITY
		card3.add_to_group("facility_cards")
		slot3.place_facility(card3)

func _on_facility_placed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility placed: ", facility_card.facility_resource.facility_name, " in slot ", slot.slot_index)

func _on_facility_removed(facility_card: FacilityCard, slot: FacilitySlot):
	print("Facility removed from slot ", slot.slot_index)

func _on_creature_clicked(creature_data: CreatureData) -> void:
	# Create and show popup
	var popup = CREATURE_STATS_POPUP.instantiate()
	add_child(popup)
	popup.setup(creature_data)

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
	for creature in creatures:
		if creature is CreatureData:
			print("  - %s needs food" % creature.creature_name)

	# TODO: Show popup with creature list and message
	# For now, visual feedback: flash the facility cards with red tint

func _spawn_tinos():
	# Spawn 2 Tinos on the platform
	for i in range(2):
		var tino = TINO_CREATURE.instantiate()
		add_child(tino)

		# Position on center platform with random X position
		var random_x = randf_range(500, 1420)
		tino.position = Vector2(random_x, 400)

		# Set platform bounds on the movement controller
		var movement_controller = tino.get_node_or_null("WanderMovementController")
		if movement_controller:
			movement_controller.platform_bounds = Vector2(400, 1520)

		print("Tino %d spawned at: %s" % [i + 1, tino.position])

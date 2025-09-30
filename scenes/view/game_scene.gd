extends Control

# Preload the debug popup scene
const DEBUG_POPUP = preload("res://scenes/windows/debug_popup.tscn")
const CREATURE_DISPLAY = preload("res://scenes/entities/creature_display.tscn")
const WEEK_DISPLAY = preload("res://scenes/card/week_display.tscn")
const FacilitySlot = preload("res://scenes/card/facility_slot.gd")


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
	# Clear and respawn creatures with loaded data
	for child in creature_container.get_children():
		if child is CreatureDisplay:
			child.queue_free()

	# Respawn creatures from loaded data
	for creature in GameManager.player_data.creatures:
		_spawn_creature(creature)

func _setup_container_drop_handling():
	if creature_container:
		# Add a Control overlay to handle drops
		var drop_overlay = Control.new()
		drop_overlay.name = "DropOverlay"
		drop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		drop_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Doesn't block mouse events
		creature_container.add_child(drop_overlay)

		# Add drop handling script
		var drop_script = preload("res://scripts/container_drop_handler.gd")
		drop_overlay.set_script(drop_script)
		drop_overlay.container = creature_container

func _create_week_display():
	var week_display = WEEK_DISPLAY.instantiate()
	add_child(week_display)
#
func _create_facility_slots():
	# Create container for facility slots
	var slot_container = HBoxContainer.new()
	slot_container.name = "FacilitySlotContainer"
	slot_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	slot_container.position = Vector2(50, -500)
	slot_container.add_theme_constant_override("separation", 20)
	add_child(slot_container)

	# Create 3 facility slots
	for i in range(3):
		var slot = FacilitySlot.new()
		slot.slot_index = i
		slot.slot_name = "Facility " + str(i + 1)
		slot.name = "FacilitySlot_" + str(i)
		slot_container.add_child(slot)

		# Connect signals
		slot.facility_placed.connect(_on_facility_placed)
		slot.facility_removed.connect(_on_facility_removed)

	# Place test facility in first slot
	_place_test_facility_in_slot()

func _place_test_facility_in_slot():
	# Get first slot
	var slot_container = $FacilitySlotContainer
	if slot_container and slot_container.get_child_count() > 0:
		var first_slot = slot_container.get_child(0)

		# Create test facility card
		var training_facility = FacilityResource.new()
		training_facility.facility_name = "Training Grounds"
		training_facility.description = "Train your creatures"
		training_facility.max_creatures = 2

		# Add a strength training activity
		var strength_activity = ActivityResource.new()
		strength_activity.activity_name = "Strength Training"
		strength_activity.description = "Gain +5 Strength"
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
	
	

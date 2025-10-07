# scenes/windows/quest_creature_selector.gd
extends CanvasLayer

@onready var title = $Panel/MarginContainer/VBoxContainer/Title
@onready var quest_info = $Panel/MarginContainer/VBoxContainer/QuestInfo
@onready var creature_grid = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var selected_info = $Panel/MarginContainer/VBoxContainer/SelectedInfo
@onready var cancel_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Button
@onready var confirm_button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Button2

var quest: QuestResource = null
var selected_creatures: Array[CreatureData] = []
var required_count: int = 0

func _ready():
	if cancel_button:
		cancel_button.pressed.connect(close_window)
	else:
		print("ERROR: cancel_button is null!")

	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	else:
		print("ERROR: confirm_button is null!")

func setup(quest_resource: QuestResource):
	quest = quest_resource

	# Calculate total creatures needed
	required_count = 0
	for req in quest.requirements:
		required_count += req.quantity 

	title.text = "Select Creatures: " + quest.quest_title
	quest_info.text = quest.get_requirements_summary()

	populate_creature_grid()
	update_selected_info()

func populate_creature_grid():
	# Clear existing
	for child in creature_grid.get_children():
		child.queue_free()

	# Add creature buttons - only show creatures that match ANY requirement
	if GameManager.player_data:
		for creature in GameManager.player_data.creatures:
			# Check if creature matches ANY requirement
			var matches_any = false
			for req in quest.requirements:
				if req.creature_matches(creature):
					matches_any = true
					break

			# Only show matching creatures
			if matches_any:
				var button = create_creature_button(creature)
				creature_grid.add_child(button)

func create_creature_button(creature: CreatureData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(220, 140)  # Wider and taller for wrapped text
	button.toggle_mode = true

	# Enable text wrapping and clipping
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false  # Allow text to wrap instead of clipping
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

	# Vertical alignment for better readability
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP

	# Button text with creature info and tags
	var species_name = GlobalEnums.Species.keys()[creature.species]
	var tags_display = creature.get_tags_display()

	button.text = "%s\n%s\nSTR:%d AGI:%d INT:%d\n%s" % [
		creature.creature_name,
		species_name,
		creature.strength,
		creature.agility,
		creature.intelligence,
		tags_display
	]

	# All creatures shown already match, so make them all green
	button.modulate = Color(0.8, 1.0, 0.8)  # Light green

	button.toggled.connect(func(pressed): _on_creature_toggled(creature, pressed, button))

	return button

func _on_creature_toggled(creature: CreatureData, pressed: bool, button: Button):
	if pressed:
		if selected_creatures.size() < required_count:
			selected_creatures.append(creature)
		else:
			# Deselect if too many
			button.button_pressed = false
			return
	else:
		selected_creatures.erase(creature)

	update_selected_info()

func find_creature_button(creature: CreatureData) -> Button:
	for child in creature_grid.get_children():
		if child is Button:
			# Match by checking creature data (simple approach)
			if creature in selected_creatures:
				return child
	return null

func update_selected_info():
	selected_info.text = "Selected: %d/%d" % [selected_creatures.size(), required_count]
	confirm_button.disabled = selected_creatures.size() != required_count

func _on_confirm_pressed():
	# Validate creatures
	var validation = quest.validate_creatures(selected_creatures)

	if validation.valid:
		# Attempt turn in
		var success = GameManager.quest_manager.complete_quest(quest.quest_id, selected_creatures)
		if success:
			close_window()
		else:
			show_error("Failed to complete quest!")
	else:
		# Show what's missing
		var missing_text = "\n".join(validation.missing)
		show_error("Requirements not met:\n" + missing_text)

func show_error(message: String):
	# Future: Show error popup
	print("ERROR: ", message)

func close_window():
	queue_free()

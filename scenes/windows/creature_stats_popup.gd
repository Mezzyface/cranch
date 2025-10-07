extends CanvasLayer

# References to labels (set in _ready via get_node)
@onready var panel_container: PanelContainer = $PanelContainer
@onready var creature_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CreatureName
@onready var species_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeciesLabel
@onready var age_label: Label = $PanelContainer/MarginContainer/VBoxContainer/AgeLabel
@onready var strength_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StrengthLabel
@onready var agility_label: Label = $PanelContainer/MarginContainer/VBoxContainer/AgilityLabel
@onready var intelligence_label: Label = $PanelContainer/MarginContainer/VBoxContainer/IntelligenceLabel
@onready var tags_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TagsLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var creature_data: CreatureData

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

	# Center popup on screen
	if panel_container:
		panel_container.position = get_viewport().get_visible_rect().size / 2 - panel_container.size / 2

func setup(creature: CreatureData) -> void:
	creature_data = creature

	# Populate labels
	creature_name_label.text = creature.creature_name
	species_label.text = "Species: " + GlobalEnums.Species.keys()[creature.species]

	# Age display
	if age_label and GameManager:
		var age = creature.get_age(GameManager.current_week)
		var remaining = creature.get_remaining_lifespan(GameManager.current_week)
		age_label.text = "Age: %d / %d weeks (%d remaining)" % [age, creature.max_lifespan, remaining]

		# Color warning if nearing death
		if remaining <= 5:
			age_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		else:
			age_label.add_theme_color_override("font_color", Color.WHITE)

	strength_label.text = "Strength: " + str(creature.strength)
	agility_label.text = "Agility: " + str(creature.agility)
	intelligence_label.text = "Intelligence: " + str(creature.intelligence)

	# Add tags display
	var tags_text = creature.get_tags_display()
	tags_label.text = "Tags: " + tags_text

func _on_close_pressed() -> void:
	queue_free()

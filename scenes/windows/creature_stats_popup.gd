extends PanelContainer

# References to labels (set in _ready via get_node)
@onready var creature_name_label: Label = $MarginContainer/VBoxContainer/CreatureName
@onready var species_label: Label = $MarginContainer/VBoxContainer/SpeciesLabel
@onready var strength_label: Label = $MarginContainer/VBoxContainer/StrengthLabel
@onready var agility_label: Label = $MarginContainer/VBoxContainer/AgilityLabel
@onready var intelligence_label: Label = $MarginContainer/VBoxContainer/IntelligenceLabel
@onready var tags_label: Label = $MarginContainer/VBoxContainer/TagsLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var creature_data: CreatureData

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

	# Center popup on screen
	position = get_viewport_rect().size / 2 - size / 2

func setup(creature: CreatureData) -> void:
	creature_data = creature

	# Populate labels
	creature_name_label.text = creature.creature_name
	species_label.text = "Species: " + GlobalEnums.Species.keys()[creature.species]
	strength_label.text = "Strength: " + str(creature.strength)
	agility_label.text = "Agility: " + str(creature.agility)
	intelligence_label.text = "Intelligence: " + str(creature.intelligence)

	# Add tags display
	var tags_text = creature.get_tags_display()
	tags_label.text = "Tags: " + tags_text

func _on_close_pressed() -> void:
	queue_free()

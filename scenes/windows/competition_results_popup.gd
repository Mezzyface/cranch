# scenes/windows/competition_results_popup.gd
extends CanvasLayer

@onready var panel = $PanelContainer
@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var results_container = $PanelContainer/MarginContainer/VBoxContainer/ResultsContainer
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var competition: CompetitionResource
var results: Array  # Array of CompetitionResult

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_display_results()
	_center_popup()

func setup(p_competition: CompetitionResource, p_results: Array):
	competition = p_competition
	results = p_results

func _display_results():
	if not competition or results.is_empty():
		return

	# Set title
	title_label.text = "%s - Results" % competition.activity_name

	# Clear existing results
	for child in results_container.get_children():
		child.queue_free()

	# Display each result
	for result in results:
		_create_result_row(result)

func _create_result_row(result):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(500, 40)

	# Placement
	var place_label = Label.new()
	place_label.text = _get_placement_text(result.placement)
	place_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(place_label)

	# Creature name
	var name_label = Label.new()
	name_label.text = result.creature.creature_name
	if result.is_player_creature:
		name_label.text += " (You)"
		name_label.add_theme_color_override("font_color", Color.GOLD)
	name_label.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(name_label)

	# Score
	var score_label = Label.new()
	score_label.text = "Score: %d" % result.score
	score_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(score_label)

	# Prize (if applicable)
	if result.is_player_creature and result.placement <= 3:
		var prize = _get_prize_amount(result.placement)
		if prize > 0:
			var prize_label = Label.new()
			prize_label.text = "+%d gold" % prize
			prize_label.add_theme_color_override("font_color", Color.YELLOW)
			hbox.add_child(prize_label)

	results_container.add_child(hbox)

func _get_placement_text(placement: int) -> String:
	match placement:
		1: return "🥇 1st"
		2: return "🥈 2nd"
		3: return "🥉 3rd"
		_: return "%dth" % placement

func _get_prize_amount(placement: int) -> int:
	match placement:
		1: return competition.first_place_gold if competition else 0
		2: return competition.second_place_gold if competition else 0
		3: return competition.third_place_gold if competition else 0
		_: return 0

func _center_popup():
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _on_close_pressed():
	queue_free()

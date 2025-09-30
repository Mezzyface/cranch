# scenes/ui/week_display.gd
extends PanelContainer

@onready var week_label: Label = $MarginContainer/HBoxContainer/Label
@onready var advance_button: Button = $MarginContainer/HBoxContainer/Button

func _ready():
	advance_button.pressed.connect(_on_advance_pressed)
	SignalBus.week_advanced.connect(_on_week_advanced)

	# Initialize display
	_update_display(GameManager.current_week)

func _on_advance_pressed():
	GameManager.advance_week()

func _on_week_advanced(new_week: int):
	_update_display(new_week)

func _update_display(week: int):
	week_label.text = "Week " + str(week)

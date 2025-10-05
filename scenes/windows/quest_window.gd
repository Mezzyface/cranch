# scenes/windows/quest_window.gd
extends CanvasLayer

@onready var panel = $Panel
@onready var quest_list_container = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestList/QuestListScroll/QuestListContainer
@onready var selected_quest_title = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/SelectedQuestTitle
@onready var quest_giver = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/QuestGiver
@onready var quest_dialogue = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/QuestDialog
@onready var requirements_text = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/RequirementsText
@onready var rewards_text = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/RewardsText
@onready var turn_in_button = $Panel/MarginContainer/MarginContainer/HSplitContainer/QuestDetails/ActionButtons/TurninButton
@onready var close_button = $Panel/Button

var selected_quest: QuestResource = null

func _ready():
	# Clear any placeholder text from the editor
	selected_quest_title.text = ""
	quest_giver.text = ""
	quest_dialogue.text = ""
	requirements_text.text = ""
	rewards_text.text = ""

	close_button.pressed.connect(_on_close_pressed)
	turn_in_button.pressed.connect(_on_turn_in_pressed)

	SignalBus.quest_accepted.connect(_on_quest_accepted)
	SignalBus.quest_completed.connect(_on_quest_completed)

	refresh_quest_list()

func _on_close_pressed():
	SignalBus.quest_log_closed.emit()
	queue_free()

func _on_turn_in_pressed():
	if selected_quest:
		GameManager.quest_manager.current_quest_for_turnin = selected_quest
		SignalBus.quest_turn_in_started.emit(selected_quest)
		# Open creature selection window (to be implemented)
		print("Select creatures to turn in for quest: ", selected_quest.quest_title)

func _on_quest_accepted(quest: QuestResource):
	refresh_quest_list()

func _on_quest_completed(quest: QuestResource):
	refresh_quest_list()
	# Show completion message
	show_quest_completed_popup(quest)

func refresh_quest_list():
	# Clear existing quest buttons
	for child in quest_list_container.get_children():
		child.queue_free()

	# Add active quests
	var available = GameManager.quest_manager.get_available_quests()
	print("QuestWindow: Available quests count: ", available.size())

	for quest in available:
		var button = Button.new()
		button.text = quest.quest_title
		button.custom_minimum_size = Vector2(0, 40)  # Set minimum height
		button.pressed.connect(func(): select_quest(quest))
		quest_list_container.add_child(button)
		print("QuestWindow: Added quest button: ", quest.quest_title)

	print("QuestWindow: Total buttons in container: ", quest_list_container.get_child_count())

	# Select first quest by default
	if available.size() > 0:
		select_quest(available[0])
	else:
		clear_quest_details()

func select_quest(quest: QuestResource):
	selected_quest = quest

	print("QuestWindow: Selecting quest: ", quest.quest_title)
	print("QuestWindow: Quest giver: ", quest.quest_giver)
	print("QuestWindow: Dialogue: ", quest.dialogue)

	# Update UI
	selected_quest_title.text = quest.quest_title
	quest_giver.text = "Quest Giver: " + quest.quest_giver
	quest_dialogue.text = quest.dialogue
	requirements_text.text = quest.get_requirements_summary()

	print("QuestWindow: Requirements summary: ", quest.get_requirements_summary())

	if quest.reward:
		rewards_text.text = quest.reward.get_description()
		print("QuestWindow: Rewards: ", quest.reward.get_description())
	else:
		rewards_text.text = "No rewards"

	turn_in_button.disabled = false

func clear_quest_details():
	selected_quest = null
	selected_quest_title.text = "No Active Quests"
	quest_giver.text = ""
	quest_dialogue.text = ""
	requirements_text.text = ""
	rewards_text.text = ""
	turn_in_button.disabled = true

func show_quest_completed_popup(quest: QuestResource):
	# Future: Show a fancy completion popup
	print("QUEST COMPLETED: ", quest.quest_title)
	if quest.reward:
		print("Rewards: ", quest.reward.get_description())

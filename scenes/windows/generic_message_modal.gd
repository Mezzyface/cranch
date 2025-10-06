extends CanvasLayer
class_name GenericMessageModal

# Configuration
var title: String = "Message"
var message: String = "This is a message"

@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)

	# Set content
	title_label.text = title
	message_label.text = message

func _on_close_pressed():
	queue_free()

# Static helper to create and show a message modal
static func show_message(parent_node: Node, p_title: String, p_message: String):
	var modal_scene = preload("res://scenes/windows/generic_message_modal.tscn")
	var modal = modal_scene.instantiate()
	modal.title = p_title
	modal.message = p_message
	parent_node.add_child(modal)

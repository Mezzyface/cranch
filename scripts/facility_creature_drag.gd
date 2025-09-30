# scripts/facility_creature_drag.gd
extends Control

var creature_data: CreatureData
var facility_card: FacilityCard


func _ready():
	print("FacilityCreatureDrag ready for creature: ", creature_data.creature_name if creature_data else "unknown")
	mouse_entered.connect(func(): print("Mouse entered creature drag area"))

func _gui_input(event):
	if event is InputEventMouseButton:
		print("Mouse button event on creature: ", creature_data.creature_name if creature_data else "unknown")
func _get_drag_data(_position: Vector2):
	print("_get_drag_data called for creature: ", creature_data.creature_name if creature_data else "unknown")
	if not creature_data:
		return null

	# Create preview
	var preview = TextureRect.new()
	var sprite = get_parent()  # The AnimatedSprite2D
	if sprite and sprite is AnimatedSprite2D:
		preview.texture = sprite.sprite_frames.get_frame_texture("idle", 0)
		preview.modulate.a = 0.7
		preview.custom_minimum_size = Vector2(64, 64)
	set_drag_preview(preview)

	# Remove from facility when picked up
	if facility_card:
		facility_card.remove_creature(creature_data)

	# Hide the sprite on the card
	get_parent().visible = false

	return {
		"creature": creature_data,
		"source_node": get_parent(),
		"from_facility": true
	}

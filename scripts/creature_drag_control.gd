# scenes/entities/creature_drag_control.gd
extends Control

var creature_parent: Node2D
var creature_data: CreatureData

func _can_drop_data(_position: Vector2, _data) -> bool:
	return false  # This is a drag source, not a drop target

func _get_drag_data(_position: Vector2):
	if not creature_data or not creature_parent:
		return null

	# Create a preview
	var preview = TextureRect.new()
	var sprite: AnimatedSprite2D = creature_parent.get_node("AnimatedSprite2D")
	preview.texture = sprite.sprite_frames.get_frame_texture("idle", 0)
	preview.modulate.a = 0.7
	preview.custom_minimum_size = Vector2(64, 64)
	set_drag_preview(preview)

	# Hide the original creature
	creature_parent.visible = false

	return {
		"creature": creature_data,
		"source_node": creature_parent
	}

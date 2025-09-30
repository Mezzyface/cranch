# scripts/container_drop_handler.gd
extends Control

var container: PanelContainer

func _can_drop_data(position: Vector2, data) -> bool:
	# Accept creatures being dragged
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("creature") and data.has("source_node")

func _drop_data(position: Vector2, data) -> void:
	# Handle dropping creature back into container
	if data.has("source_node") and is_instance_valid(data.source_node):
		var creature = data.source_node

		# Make creature visible again
		creature.visible = true

		# Convert global position to container local position
		var local_pos = container.get_global_transform().affine_inverse() * position

		# Apply position with padding constraints
		var padding = 20.0
		var container_size = container.get_rect().size
		creature.position = Vector2(
			clamp(local_pos.x, padding, container_size.x - padding),
			clamp(local_pos.y, padding, container_size.y - padding)
		)

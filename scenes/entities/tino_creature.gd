extends CharacterBody2D

@export var creature_data: CreatureData
@export var hitbox_scale: float = 0.8  # Scale hitbox to 80% of sprite size (for more forgiving collision)

@onready var movement_controller = $WanderMovementController
@onready var drag_component = $DragDropComponent
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Wait a frame for all components to be ready
	await get_tree().process_frame

	# Update sprite based on creature data
	_update_sprite()

	# Update hitbox to match sprite size
	_update_hitbox()

	# Setup drag component
	if drag_component:
		drag_component.drag_data_source = self
		drag_component.can_drag = true
		drag_component.drag_type = DragDropComponent.DragType.CREATURE
		drag_component.mouse_filter_mode = Control.MOUSE_FILTER_STOP

		# Connect drag signals for visual feedback
		drag_component.drag_started.connect(func(_data):
			modulate.a = 0.5  # Make semi-transparent when dragging
		)

		drag_component.drag_ended.connect(func(_successful):
			modulate.a = 1.0  # Restore opacity
		)

func _update_sprite():
	if not creature_data or not animated_sprite:
		return

	# Get sprite frames for this creature's species
	var sprite_frames = GlobalEnums.get_sprite_frames_for_species(creature_data.species)
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.play("idle")

func _update_hitbox():
	if not animated_sprite or not collision_shape:
		return

	# Wait for sprite frames to be loaded
	await get_tree().process_frame

	# Get the current frame's texture to determine size
	var current_texture = animated_sprite.get_sprite_frames().get_frame_texture(animated_sprite.animation, 0)

	if current_texture:
		var sprite_size = current_texture.get_size()

		# Create or update the rectangle shape
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = sprite_size * hitbox_scale

		collision_shape.shape = rect_shape

		# Position collision shape so bottom aligns with sprite bottom
		# Sprite is centered by default, so offset down by half the hitbox height
		var offset_y = (sprite_size.y - rect_shape.size.y) / 2.0
		collision_shape.position = Vector2(0, offset_y)

func _physics_process(delta):
	if movement_controller:
		movement_controller.process_movement(delta)

func get_drag_data() -> Dictionary:
	if creature_data:
		return {
			"creature": creature_data,
			"source_node": self
		}
	return {}
